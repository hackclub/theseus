# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingSettlementSweepJob do
  let(:user) { create(:user) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:other) { create(:billing_profile, user: user, organization_id: "org_b") }
  let(:batch) { create(:letter_batch, user: user) }

  before { fake_hcb! }

  it "charges unclaimed entries once per profile and retries due transfers" do
    batch.ledger_entries.create!(billing_profile: profile, category: :postage, amount_cents: 100)
    batch.ledger_entries.create!(billing_profile: profile, category: :labor, amount_cents: 250)
    batch.ledger_entries.create!(billing_profile: other, category: :postage, amount_cents: 400)

    hq = Billing.destination_for(:labor)
    due = HCB::Transfer.create!(billing_profile: profile, hq_organization_id: hq, amount_cents: 999, name: "old", state: :failed, attempts: 1, next_attempt_at: 1.minute.ago)
    batch.ledger_entries.create!(billing_profile: profile, category: :labor, amount_cents: 999, hcb_transfer: due)
    not_due = HCB::Transfer.create!(billing_profile: profile, hq_organization_id: hq, amount_cents: 998, name: "later", state: :failed, attempts: 1, next_attempt_at: 1.hour.from_now)
    stuck = HCB::Transfer.create!(billing_profile: profile, hq_organization_id: hq, amount_cents: 997, name: "stuck", state: :unknown, attempts: 1)

    # `profile` has an unknown transfer in flight, so only `other` gets charged this sweep
    described_class.new.perform

    amounts = hcb_disbursements.map { |d| d[:amount_cents] }
    expect(amounts).to contain_exactly(400, 999)
    expect(due.reload).to be_completed
    expect(not_due.reload).to be_failed
    expect(stuck.reload).to be_unknown
    expect(LedgerEntry.unclaimed.count).to eq(2)

    stuck.update!(state: :completed, remote_id: "xfr_resolved")
    described_class.new.perform
    expect(hcb_disbursements.last[:amount_cents]).to eq(350)
    expect(LedgerEntry.unclaimed).to be_empty
  end

  it "sends a pending transfer that was created but never executed" do
    entry = batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: 250)
    transfer = Billing.charge!([ entry ], name: "x", execute: false)
    described_class.new.perform
    expect(transfer.reload).to be_pending

    transfer.update!(created_at: 10.minutes.ago)
    described_class.new.perform
    expect(transfer.reload).to be_completed
    expect(entry.reload).to be_settled
  end
end
