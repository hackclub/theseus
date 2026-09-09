# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing do
  let(:user) { create(:user) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:batch) { create(:letter_batch, user: user) }

  before { fake_hcb! }

  def entry(cents = 500, category: :indicia, ledgerable: batch)
    ledgerable.ledger_entries.create!(billing_profile: profile, category: category, amount_cents: cents)
  end

  describe ".charge!" do
    it "creates the transfer before the request, then settles the entries" do
      a, b = entry(300), entry(200)
      transfer = Billing.charge!([a, b], name: "Postage")

      expect(transfer).to be_completed
      expect(transfer).to be_debit
      expect(transfer.amount_cents).to eq(500)
      expect(transfer.remote_id).to eq("xfr_fake1")
      expect(transfer.attempts).to eq(1)
      expect([a, b].map { |e| e.reload.state }).to all(eq("settled"))
      expect([a, b].map { |e| e.hcb_transfer_id }).to all(eq(transfer.id))

      sent = hcb_disbursements.first
      expect(sent[:amount_cents]).to eq(500)
      expect(sent[:to_organization_id]).to eq(Billing.destination_for(:indicia))
      expect(transfer.hq_organization_id).to eq(Billing.destination_for(:indicia))
      expect(sent[:name]).to eq("Postage [#{transfer.idempotency_key}]")
      expect(hcb_memos.first[1]).to include("[#{transfer.idempotency_key}]")
    end

    it "returns nil with nothing to claim" do
      expect(Billing.charge!([], name: "x")).to be_nil
      settled = entry.tap { |e| Billing.charge!([e], name: "x") }
      expect(Billing.charge!([settled], name: "again")).to be_nil
      expect(hcb_disbursements.size).to eq(1)
    end

    it "refuses to mix USPS and warehouse work in one transfer, and charge_pending! splits them" do
      indicia = entry(500, category: :indicia)
      labor = entry(200, category: :labor)
      expect { Billing.charge!([indicia, labor], name: "x") }.to raise_error(ArgumentError, /destinations/)
      expect(HCB::Transfer.count).to eq(0)

      transfers = Billing.charge_pending!(profile)
      expect(transfers.map(&:hq_organization_id)).to contain_exactly(Billing.destination_for(:indicia), Billing.destination_for(:labor))
      expect(transfers.map(&:amount_cents)).to contain_exactly(500, 200)
      expect(LedgerEntry.unclaimed).to be_empty
    end

    it "never claims credits or entries from another profile together" do
      a = entry(500)
      other = create(:billing_profile, user: user, organization_id: "org_b")
      b = batch.ledger_entries.create!(billing_profile: other, category: :indicia, amount_cents: 100)
      expect { Billing.charge!([a, b], name: "x") }.to raise_error(ArgumentError, /multiple billing profiles/)
      expect(HCB::Transfer.count).to eq(0)
    end

    it "does not double-claim under concurrency" do
      e = entry(500)
      results = 4.times.map do
        Thread.new { ActiveRecord::Base.connection_pool.with_connection { Billing.charge!([e], name: "race") } }
      end.map(&:value)
      expect(results.compact.size).to eq(1)
      expect(hcb_disbursements.size).to eq(1)
    end

    context "when a transfer is already in flight for the profile" do
      before do
        stuck = entry(100)
        t = Billing.charge!([stuck], name: "first", execute: false)
        t.update!(state: :unknown, last_attempted_at: 1.minute.ago)
      end

      it "leaves entries unclaimed (non-strict)" do
        e = entry(200)
        expect(Billing.charge!([e], name: "second")).to be_nil
        expect(e.reload.hcb_transfer_id).to be_nil
        expect(hcb_disbursements).to be_empty
      end

      it "raises InFlight (strict)" do
        e = entry(200)
        expect { Billing.charge!([e], name: "second", strict: true) }.to raise_error(Billing::InFlight)
        expect(e.reload.hcb_transfer_id).to be_nil
      end
    end

    it "honours MOCK_HCB without touching HCB" do
      allow(Billing).to receive(:mock?).and_return(true)
      t = Billing.charge!([entry], name: "x")
      expect(t).to be_completed
      expect(t.remote_id).to start_with("mock_")
      expect(hcb_disbursements).to be_empty
    end

    it "never loses the remote id if settling entries blows up" do
      e = entry(500)
      allow_any_instance_of(HCB::Transfer).to receive(:settle_entries!).and_raise("db hiccup")
      expect { Billing.charge!([e], name: "x") }.to raise_error("db hiccup")
      transfer = HCB::Transfer.sole
      expect(transfer).to be_completed
      expect(transfer.remote_id).to eq("xfr_fake1")
      expect(e.reload).to be_pending

      allow_any_instance_of(HCB::Transfer).to receive(:settle_entries!).and_call_original
      BillingSettlementSweepJob.new.perform
      expect(e.reload).to be_settled
      expect(hcb_disbursements.size).to eq(1)
    end
  end

  describe "error classification" do
    let(:e) { entry(500) }

    it "marks a 422 as failed + retryable and keeps the claim" do
      mails = capture_billing_mail
      hcb_raises(api_error(HCBV4::UnprocessableEntityError, "You don't have enough money to make this disbursement.", status: 422, error_code: "invalid_operation"))
      transfer = Billing.charge!([e], name: "x")

      expect(transfer).to be_failed
      expect(transfer).to be_retryable
      expect(transfer.next_attempt_at).to be > Time.current
      expect(transfer.last_error).to include("enough money")
      expect(e.reload).to be_pending
      expect(e.hcb_transfer_id).to eq(transfer.id)
      expect(mails).to have_received(:insufficient_funds).once
    end

    it "marks oauth/credential failures as failed + not retryable and invalidates the connection" do
      hcb_raises(OAuth2::Error.new(double(parsed: { "error" => "invalid_grant" }, body: "", status: 400, response: nil)))
      transfer = Billing.charge!([e], name: "x")
      expect(transfer).to be_failed
      expect(transfer).not_to be_retryable
      expect(profile.oauth_connection.reload).to be_invalidated
    end

    it "treats a connection failure as definite (nothing sent)" do
      hcb_raises(Faraday::ConnectionFailed.new("ECONNREFUSED"))
      expect(Billing.charge!([e], name: "x")).to be_failed
    end

    it "marks timeouts as unknown and never retries them" do
      mails = capture_billing_mail
      hcb_raises(Faraday::TimeoutError.new("Net::ReadTimeout"))
      transfer = Billing.charge!([e], name: "x")
      expect(transfer).to be_unknown
      expect(transfer.next_attempt_at).to be_nil
      expect(HCB::Transfer.due_for_retry).to be_empty
      expect(e.reload).to be_pending

      expect(mails).to have_received(:transfer_unknown).once

      # A second execute is a no-op
      Billing.execute!(transfer)
      expect(transfer.reload.attempts).to eq(1)
    end

    it "marks 5xx as unknown" do
      hcb_raises(api_error(HCBV4::ServerError, "Internal Server Error", status: 500))
      expect(Billing.charge!([e], name: "x")).to be_unknown
    end

    it "raises typed errors in strict mode" do
      hcb_raises(Faraday::TimeoutError.new("boom"))
      expect { Billing.charge!([e], name: "x", strict: true) }.to raise_error(Billing::Unconfirmed)
      hcb_raises(api_error(HCBV4::BadRequestError, "nope", status: 400))
      expect { Billing.charge!([entry], name: "x", strict: true) }.to raise_error(Billing::InFlight) # first one is still unknown
    end

    it "retries a failed transfer with the same key and gives up after MAX_ATTEMPTS" do
      hcb_raises(api_error(HCBV4::RateLimitError, "slow down", status: 429))
      transfer = Billing.charge!([e], name: "x")
      key = transfer.idempotency_key

      (HCB::Transfer::MAX_ATTEMPTS - 1).times do
        transfer.update!(next_attempt_at: 1.minute.ago)
        Billing.execute!(transfer)
      end
      expect(transfer.reload.attempts).to eq(HCB::Transfer::MAX_ATTEMPTS)
      expect(transfer).to be_gave_up
      expect(transfer.idempotency_key).to eq(key)

      fake_hcb!
      transfer.retry!
      Billing.execute!(transfer)
      expect(transfer.reload).to be_completed
      expect(hcb_disbursements.last[:name]).to end_with("[#{key}]")
      expect(e.reload).to be_settled
    end

    it "does not fail the transfer when only the memo write fails" do
      allow_any_instance_of(BillingProfile).to receive(:set_transaction_memo!).and_raise(Faraday::TimeoutError.new("memo"))
      transfer = Billing.charge!([e], name: "x")
      expect(transfer).to be_completed
      expect(transfer.metadata["memo_pending"]).to be(true)
      expect(e.reload).to be_settled
    end
  end

  describe ".credit!" do
    let(:original) { entry(1000).tap { |x| Billing.charge!([x], name: "charge") }.reload }

    it "creates a negative entry and a credit transfer to the org" do
      transfer = Billing.credit!(reverses: original, amount_cents: 300, name: "Refund")
      expect(transfer).to be_completed
      expect(transfer).to be_credit
      credit = transfer.ledger_entries.sole
      expect(credit.amount_cents).to eq(-300)
      expect(credit.reverses).to eq(original)
      expect(credit).to be_settled
      expect(original.reload.net_cents).to eq(700)
      expect(batch.total_billed_cents).to eq(700)

      sent = hcb_disbursements.last
      expect(sent[:direction]).to eq(:credit)
      expect(sent[:organization_id]).to eq(profile.organization_id)
      expect(sent[:from_organization_id]).to eq(Billing.destination_for(:indicia))
      expect(transfer.hq_organization_id).to eq(original.hcb_transfer.hq_organization_id)
      expect(sent[:amount_cents]).to eq(300)
    end

    it "refuses to over-credit, credit unsettled charges, or run while in flight" do
      expect { Billing.credit!(reverses: original, amount_cents: 1001, name: "x") }.to raise_error(ArgumentError, /only \$10\.00 remains/)
      pending_entry = entry(100)
      expect { Billing.credit!(reverses: pending_entry, amount_cents: 50, name: "x") }.to raise_error(ArgumentError, /settled/)

      Billing.credit!(reverses: original, amount_cents: 100, name: "x", execute: false)
      expect { Billing.credit!(reverses: original, amount_cents: 100, name: "y") }.to raise_error(Billing::InFlight)
    end

    it "is strict: a rejected refund raises and leaves the credit pending" do
      hcb_raises(api_error(HCBV4::BadRequestError, "nope", status: 400), direction: :credit)
      expect { Billing.credit!(reverses: original, amount_cents: 300, name: "x") }.to raise_error(Billing::Rejected)
      credit = LedgerEntry.credits.sole
      expect(credit).to be_pending
      expect(credit.hcb_transfer).to be_failed
      expect(original.reload.net_cents).to eq(700) # pending credit still counts against the charge
    end
  end
end
