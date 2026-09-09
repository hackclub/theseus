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

  describe ".destination_for" do
    def with_env(name, value)
      had = ENV.key?(name)
      old = ENV[name]
      ENV[name] = value
      yield
    ensure
      had ? ENV[name] = old : ENV.delete(name)
    end

    it "treats a blank HCB_USPS_ORG_ID as missing instead of charging a blank org" do
      e = entry(500, category: :indicia)

      with_env("HCB_USPS_ORG_ID", "") do
        expect { Billing.destination_for(:indicia) }.to raise_error(KeyError, /HCB_USPS_ORG_ID is blank/)
        expect { Billing.charge!([ e ], name: "x") }.to raise_error(KeyError)
      end

      # nothing sent, nothing claimed
      expect(hcb_disbursements).to be_empty
      expect(HCB::Transfer.count).to eq(0)
      expect(e.reload).to be_pending
      expect(LedgerEntry.unclaimed).to include(e)
    end

    it "treats a blank HCB_WAREHOUSE_ORG_ID as missing" do
      e = entry(500, category: :labor)

      with_env("HCB_WAREHOUSE_ORG_ID", "") do
        expect { Billing.destination_for(:labor) }.to raise_error(KeyError, /HCB_WAREHOUSE_ORG_ID is blank/)
        expect { Billing.charge!([ e ], name: "x") }.to raise_error(KeyError)
      end

      expect(hcb_disbursements).to be_empty
      expect(HCB::Transfer.count).to eq(0)
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

      transfer.update!(next_attempt_at: 1.minute.ago)
      Billing.execute!(transfer)
      expect(transfer.reload.attempts).to eq(2)
      expect(mails).to have_received(:insufficient_funds).once  # retries are quiet
    end

    it "marks oauth/credential failures as failed + not retryable and invalidates the connection" do
      hcb_raises(OAuth2::Error.new(double(parsed: { "error" => "invalid_grant" }, body: "", status: 400, response: nil)))
      transfer = Billing.charge!([e], name: "x")
      expect(transfer).to be_failed
      expect(transfer).not_to be_retryable
      expect(profile.oauth_connection.reload).to be_invalidated
    end

    it "treats a refused connection as definite but a reset as unknown" do
      hcb_raises(Faraday::ConnectionFailed.new(Errno::ECONNREFUSED.new))
      expect(Billing.charge!([ e ], name: "x")).to be_failed

      hcb_raises(Faraday::ConnectionFailed.new(Errno::ECONNRESET.new))
      expect(Billing.charge!([ entry ], name: "x")).to be_unknown
    end

    it "stays quiet while a failure is being retried and emails once it gives up" do
      mails = capture_billing_mail
      hcb_raises(api_error(HCBV4::RateLimitError, "slow down", status: 429))
      transfer = Billing.charge!([ e ], name: "x")
      expect(mails).not_to have_received(:transfer_failed)

      (HCB::Transfer::MAX_ATTEMPTS - 1).times do
        transfer.update!(next_attempt_at: 1.minute.ago)
        Billing.execute!(transfer)
      end
      expect(transfer.reload).to be_gave_up
      expect(mails).to have_received(:transfer_failed).once
    end

    it "classifies a refused connection during token refresh as definite" do
      inner = Faraday::ConnectionFailed.new(Errno::ECONNREFUSED.new)
      hcb_raises(OAuth2::ConnectionError.new(inner))
      transfer = Billing.charge!([ e ], name: "x")
      expect(transfer).to be_failed
      expect(transfer).to be_retryable
      expect(profile.oauth_connection.reload).not_to be_invalidated
    end

    it "lets only one runner take an attempt" do
      hcb_raises(api_error(HCBV4::RateLimitError, "slow down", status: 429))
      transfer = Billing.charge!([ e ], name: "x")
      transfer.update!(next_attempt_at: 1.minute.ago)
      fake_hcb!

      allow_any_instance_of(HCB::Transfer).to receive(:begin_attempt!).and_wrap_original do |m, *args|
        m.call(*args)
        # a second runner arrives after the first has claimed the attempt
        expect(Billing::Executor.new(HCB::Transfer.find(transfer.id)).call).to be_pending
      end
      Billing.execute!(transfer)
      expect(hcb_disbursements.size).to eq(1)
    end

    it "abandons a strict rejection so the sweep can't ghost-charge a voided entry" do
      hcb_raises(api_error(HCBV4::UnprocessableEntityError, "You don't have enough money", status: 422))
      expect { Billing.charge!([ e ], name: "x", strict: true) }.to raise_error(Billing::Rejected)
      transfer = HCB::Transfer.sole
      expect(transfer).to be_abandoned
      expect(transfer).not_to be_retryable
      e.reload.void!(reason: "rejected")

      fake_hcb!
      transfer.update!(next_attempt_at: 1.minute.ago)
      BillingSettlementSweepJob.new.perform
      expect(hcb_disbursements).to be_empty
      expect(transfer.reload).to be_failed
      expect { transfer.retry! }.to raise_error(/no pending ledger entries/)
    end

    it "refuses to send a transfer whose entries no longer add up" do
      mails = capture_billing_mail
      transfer = Billing.charge!([ e ], name: "x", execute: false)
      e.update_columns(state: LedgerEntry.states[:voided])
      Billing.execute!(transfer)
      expect(transfer.reload).to be_failed
      expect(transfer.last_error).to include("ledger mismatch")
      expect(hcb_disbursements).to be_empty
      expect(mails).to have_received(:transfer_failed)
    end

    it "won't void or destroy an entry claimed by a live transfer" do
      hcb_raises(Faraday::TimeoutError.new("boom"))
      Billing.charge!([ e ], name: "x")
      expect { e.reload.void! }.to raise_error(ArgumentError, /claimed by transfer/)
      expect(e.reload.destroy).to be(false)

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

    it "treats a missing ENV var as definite, not unknown" do
      mails = capture_billing_mail
      hcb_raises(KeyError.new("key not found: \"HCB_WAREHOUSE_ORG_ID\""))
      transfer = Billing.charge!([e], name: "x")

      expect(transfer).to be_failed
      expect(transfer).not_to be_retryable
      expect(transfer.last_error).to include("HCB_WAREHOUSE_ORG_ID")
      expect(e.reload).to be_pending
      expect(hcb_disbursements).to be_empty
      expect(mails).to have_received(:transfer_failed).once
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

    it "is strict: a rejected refund raises, abandons the transfer, and voids the credit" do
      hcb_raises(api_error(HCBV4::BadRequestError, "nope", status: 400), direction: :credit)
      expect { Billing.credit!(reverses: original, amount_cents: 300, name: "x") }.to raise_error(Billing::Rejected)
      credit = LedgerEntry.credits.sole
      expect(credit).to be_voided
      expect(credit.hcb_transfer).to be_failed
      expect(credit.hcb_transfer).to be_abandoned
      expect(original.reload.net_cents).to eq(1000)
    end

    it "releases the credit when a two-phase refund is rejected" do
      transfer = Billing.credit!(reverses: original, amount_cents: 300, name: "x", execute: false)
      hcb_raises(api_error(HCBV4::BadRequestError, "nope", status: 400), direction: :credit)
      expect { Billing.execute!(transfer, strict: true) }.to raise_error(Billing::Rejected)
      expect(transfer.ledger_entries.sole.reload).to be_voided
      expect(original.reload.net_cents).to eq(1000)
    end

    it "writes memos with public ids and entry ids" do
      transfer = Billing.credit!(reverses: original, amount_cents: 300, name: "Refund", note: "overpaid")
      credit = transfer.ledger_entries.sole
      expect(original.hcb_transfer.memo).to eq("[theseus] indicia #{batch.public_id} $10.00 (T##{original.id})")
      expect(transfer.memo).to eq("[theseus] refund indicia #{batch.public_id} $3.00 (T##{credit.id} reverses T##{original.id}) · overpaid")
    end
  end
end
