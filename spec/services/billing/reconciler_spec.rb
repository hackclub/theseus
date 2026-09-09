# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Reconciler do
  let(:user) { create(:user) }
  let(:profile) { create(:billing_profile, user: user, organization_id: "org_abc") }
  let(:batch) { create(:letter_batch, user: user) }
  let(:hq_id) { Billing.destination_for(:indicia) }
  let(:hq) { FakeHCB::RemoteOrg.new(id: hq_id, slug: "hq-usps-ops", name: "HQ USPS") }
  let(:org) { FakeHCB::RemoteOrg.new(id: "org_abc", slug: "abc", name: "ABC") }

  before { fake_hcb! }

  def unknown_transfer(cents = 500, direction: :debit, created_at: 5.minutes.ago)
    entry = batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: cents)
    t = HCB::Transfer.create!(billing_profile: profile, direction: direction, hq_organization_id: hq_id, amount_cents: cents, name: "x", created_at: created_at)
    entry.update!(hcb_transfer: t)
    t.update!(state: :unknown, attempts: 1, last_attempted_at: created_at, last_error: "timeout")
    t
  end

  Tx = Struct.new(:id, :memo, :transfer, keyword_init: true)

  def remote(id:, cents:, from: org, to: hq, memo: nil)
    Tx.new(id: "txn_#{id}", memo: memo || "Transfer from ABC to HQ",
      transfer: FakeHCB::RemoteTransfer.new(id: id, transaction_id: "txn_#{id}", amount_cents: cents, memo: memo, from: from, to: to))
  end

  # Stands in for HCBV4::TransactionList: pages of transactions, each knowing
  # whether anything follows it. `more:` says there are further pages beyond
  # the ones handed in — i.e. the ceiling is real.
  FakePage = Struct.new(:txs, :more, keyword_init: true) do
    def each(&block) = txs.each(&block)
    def has_more? = !!more
  end

  FakeList = Struct.new(:pages, :more, keyword_init: true) do
    def each_page
      return enum_for(:each_page) unless block_given?
      pages.each_with_index do |txs, i|
        last = i == pages.size - 1
        page = FakePage.new(txs: txs, more: last ? more : true)
        yield page
        break unless page.has_more?
        raise "fake list ran off the end: reconciler asked for page #{i + 2}" if last
      end
    end
  end

  def stub_hq_transactions(*txs, pages: nil, more: false)
    list = FakeList.new(pages: pages || [ txs ], more: more)
    client = double("theseus client")
    allow(client).to receive(:transactions).with(hq_id, hash_including(:filters)).and_return(list)
    allow(BillingProfile).to receive(:theseus_client).and_return(client)
    client
  end

  it "completes an unknown debit that matches exactly one untagged remote transfer" do
    t = unknown_transfer(500)
    stub_hq_transactions(
      remote(id: "xfr_other", cents: 999),
      remote(id: "xfr_ours", cents: 500),
      remote(id: "xfr_tagged", cents: 500, memo: "already recorded [th_abc123]"),
    )

    result = described_class.new(t).call
    expect(result.outcome).to eq(:completed)
    expect(t.reload).to be_completed
    expect(t.remote_id).to eq("xfr_ours")
    expect(t.ledger_entries.sole).to be_settled
    expect(t.metadata["reconciled_by"]).to eq("match")
    expect(hcb_memos.last[1]).to include("[#{t.idempotency_key}]")
  end

  it "excludes remote ids we already hold" do
    earlier = unknown_transfer(500)
    earlier.update!(state: :completed, remote_id: "xfr_known")
    t = unknown_transfer(500)
    stub_hq_transactions(remote(id: "xfr_known", cents: 500))

    expect(described_class.new(t).call.outcome).to eq(:waiting)
    expect(t.reload).to be_unknown
  end

  it "treats a memo carrying our own key as a definite match, outranking everything else" do
    t = unknown_transfer(500)
    stub_hq_transactions(
      remote(id: "xfr_decoy", cents: 500),                                              # would match on amount alone
      remote(id: "xfr_ours", cents: 999, memo: "Postage [#{t.idempotency_key}]"),       # HCB reflected our tagged_name
    )

    expect(described_class.new(t).call.outcome).to eq(:completed)
    expect(t.reload).to be_completed
    expect(t.remote_id).to eq("xfr_ours")
    expect(t.metadata["reconciled_by"]).to eq("match")
  end

  it "still excludes a remote transfer carrying somebody else's key" do
    t = unknown_transfer(500)
    stub_hq_transactions(remote(id: "xfr_theirs", cents: 500, memo: "Postage [th_someotherkey]"))

    expect(described_class.new(t).call.outcome).to eq(:waiting)
    expect(t.reload).to be_unknown
  end

  it "matches credits on the destination org" do
    t = unknown_transfer(300, direction: :credit)
    stub_hq_transactions(
      remote(id: "xfr_in", cents: 300, from: org, to: hq),   # wrong direction
      remote(id: "xfr_out", cents: 300, from: hq, to: org),
    )
    expect(described_class.new(t).call.outcome).to eq(:completed)
    expect(t.reload.remote_id).to eq("xfr_out")
  end

  it "waits inside the grace period, then marks absent transfers failed-retryable" do
    young = unknown_transfer(500, created_at: 10.minutes.ago)
    stub_hq_transactions
    expect(described_class.new(young).call.outcome).to eq(:waiting)
    expect(young.reload).to be_unknown

    old = unknown_transfer(700, created_at: 3.hours.ago)
    expect(described_class.new(old).call.outcome).to eq(:failed)
    expect(old.reload).to be_failed
    expect(old).to be_retryable
    expect(old.metadata["reconciled_by"]).to eq("absent")
  end

  it "measures the grace period from the last attempt, not from creation" do
    # NSF backoff can keep a transfer alive for hours; the attempt that went
    # unknown is what HCB is still catching up on.
    t = unknown_transfer(500, created_at: 3.hours.ago)
    t.update!(attempts: 4, last_attempted_at: 10.minutes.ago)
    stub_hq_transactions

    expect(described_class.new(t).call.outcome).to eq(:waiting)
    expect(t.reload).to be_unknown
    expect(t.metadata["reconciled_by"]).to be_nil
  end

  it "reads across pages" do
    t = unknown_transfer(500)
    stub_hq_transactions(pages: [
      [ remote(id: "xfr_noise", cents: 999) ],
      [ remote(id: "xfr_ours", cents: 500) ]
    ])

    expect(described_class.new(t).call.outcome).to eq(:completed)
    expect(t.reload.remote_id).to eq("xfr_ours")
  end

  it "keeps paginating well past the old five-page budget" do
    t = unknown_transfer(500)
    pages = Array.new(5) { |i| [ remote(id: "xfr_noise#{i}", cents: 999) ] }
    pages << [ remote(id: "xfr_ours", cents: 500) ]
    stub_hq_transactions(pages: pages)

    expect(described_class.new(t).call.outcome).to eq(:completed)
    expect(t.reload.remote_id).to eq("xfr_ours")
  end

  it "will not declare a transfer absent when even the safety valve is hit, and says so once" do
    allow(Billing::Alert).to receive(:reconcile_truncated).and_call_original
    t = unknown_transfer(500, created_at: 3.hours.ago)
    pages = Array.new(described_class::MAX_PAGES + 2) { |i| [ remote(id: "xfr_noise#{i}", cents: 999) ] }
    stub_hq_transactions(pages: pages)

    result = described_class.new(t).call
    expect(result.outcome).to eq(:waiting)
    expect(t.reload).to be_unknown
    expect(t.metadata["reconciled_by"]).to eq("ceiling")
    expect(Billing::Alert).to have_received(:reconcile_truncated).with(t, described_class::MAX_PAGES).once

    # the reconcile cron runs again: still stuck, but we don't re-alert
    expect(described_class.new(t.reload).call.outcome).to eq(:waiting)
    expect(Billing::Alert).to have_received(:reconcile_truncated).once
  end

  it "does declare it absent when the listing was exhausted inside the safety valve" do
    allow(Billing::Alert).to receive(:reconcile_truncated)
    t = unknown_transfer(500, created_at: 3.hours.ago)
    pages = Array.new(described_class::MAX_PAGES) { |i| [ remote(id: "xfr_noise#{i}", cents: 999) ] }
    stub_hq_transactions(pages: pages, more: false)

    expect(described_class.new(t).call.outcome).to eq(:failed)
    expect(t.reload.metadata["reconciled_by"]).to eq("absent")
    expect(Billing::Alert).not_to have_received(:reconcile_truncated)
  end

  it "flags ambiguous matches for a human instead of guessing" do
    mails = capture_billing_mail
    t = unknown_transfer(500)
    stub_hq_transactions(remote(id: "xfr_a", cents: 500), remote(id: "xfr_b", cents: 500))

    expect(described_class.new(t).call.outcome).to eq(:ambiguous)
    expect(t.reload).to be_unknown
    expect(t.metadata["reconcile_ambiguous"]).to eq(%w[xfr_a xfr_b])
    expect(mails).to have_received(:reconcile_ambiguous)
  end

  it "treats a pending transfer that was attempted long ago as needing reconciliation" do
    t = unknown_transfer(500)
    t.update!(state: :pending, last_attempted_at: 30.minutes.ago)
    fresh = unknown_transfer(500)
    fresh.update!(state: :pending, last_attempted_at: 10.seconds.ago)
    expect(HCB::Transfer.needs_reconciliation).to contain_exactly(t)
  end
end
