# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: ledger_entries
#
#  id                 :bigint           not null, primary key
#  amount_cents       :integer          not null
#  category           :integer          not null
#  ledgerable_type    :string           not null
#  metadata           :jsonb
#  settled_at         :datetime
#  state              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  billing_profile_id :bigint           not null
#  hcb_transfer_id    :bigint
#  ledgerable_id      :bigint           not null
#  reverses_id        :bigint
#
# Indexes
#
#  index_ledger_entries_on_billing_profile_id            (billing_profile_id)
#  index_ledger_entries_on_billing_profile_id_and_state  (billing_profile_id,state)
#  index_ledger_entries_on_category                      (category)
#  index_ledger_entries_on_hcb_transfer_id               (hcb_transfer_id)
#  index_ledger_entries_on_ledgerable                    (ledgerable_type,ledgerable_id)
#  index_ledger_entries_on_reverses_id                   (reverses_id)
#  index_ledger_entries_on_state                         (state)
#  index_ledger_entries_unclaimed                        (state,hcb_transfer_id)
#
# Foreign Keys
#
#  fk_rails_...  (billing_profile_id => hcb_payment_accounts.id)
#  fk_rails_...  (hcb_transfer_id => hcb_transfers.id)
#  fk_rails_...  (reverses_id => ledger_entries.id)
#
RSpec.describe LedgerEntry do
  let(:user) { create(:user) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:batch) { create(:letter_batch, user: user) }

  def charge(cents = 500, **attrs)
    batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: cents, **attrs)
  end

  it "rejects zero amounts at the model and the database" do
    expect(charge(0)).not_to be_valid rescue expect { charge(0) }.to raise_error(ActiveRecord::RecordInvalid)
    expect { batch.ledger_entries.insert!({ billing_profile_id: profile.id, category: 3, amount_cents: 0 }) }
      .to raise_error(ActiveRecord::StatementInvalid, /ledger_entries_amount_nonzero/)
  end

  it "is immutable in amount, category, ledgerable and profile" do
    entry = charge
    expect { entry.update!(amount_cents: 999) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect { entry.update!(category: :labor) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect { entry.update!(billing_profile: create(:billing_profile, user: user, organization_id: "org_x")) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(entry.reload.amount_cents).to eq(500)
  end

  describe "state" do
    it "settles only from pending" do
      entry = charge
      transfer = HCB::Transfer.create!(billing_profile: profile, hq_organization_id: "hq-usps-ops", amount_cents: 500, name: "t")
      entry.settle!(transfer)
      expect(entry).to be_settled
      expect(entry.settled_at).to be_present
      expect { entry.settle!(transfer) }.to raise_error(ArgumentError)
      expect { entry.void! }.to raise_error(ArgumentError)
    end

    it "voids only from pending and excludes voided from totals" do
      entry = charge
      entry.void!(reason: "nope")
      expect(entry).to be_voided
      expect(entry.metadata["voided_reason"]).to eq("nope")
      expect(batch.total_billed_cents).to eq(0)
    end
  end

  describe "credits" do
    let(:transfer) { HCB::Transfer.create!(billing_profile: profile, hq_organization_id: "hq-usps-ops", amount_cents: 500, name: "t") }
    let(:original) { charge.tap { |e| e.settle!(transfer) } }

    it "must reverse a charge on the same profile" do
      other_profile = create(:billing_profile, user: user, organization_id: "org_other")
      bad = batch.ledger_entries.build(billing_profile: other_profile, category: :indicia, amount_cents: -100, reverses: original)
      expect(bad).not_to be_valid
      expect(bad.errors[:reverses]).to include("must be on the same billing profile")

      orphan = batch.ledger_entries.build(billing_profile: profile, category: :indicia, amount_cents: -100)
      expect(orphan).not_to be_valid
    end

    it "cannot exceed what remains on the charge" do
      batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: -400, reverses: original)
      expect(original.net_cents).to eq(100)
      too_much = batch.ledger_entries.build(billing_profile: profile, category: :indicia, amount_cents: -200, reverses: original)
      expect(too_much).not_to be_valid
      expect(too_much.errors[:amount_cents]).to include("would credit more than was charged")
    end

    it "nets out in Ledgerable totals" do
      batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: -150, reverses: original)
      expect(batch.total_charged_cents).to eq(500)
      expect(batch.total_credited_cents).to eq(150)
      expect(batch.total_billed_cents).to eq(350)
      expect(batch.total_billed_cents(:labor)).to eq(0)
    end
  end

  it "can be deleted only while pending" do
    entry = charge
    expect(entry.destroy).to be_truthy
    settled = charge.tap { |e| e.settle!(HCB::Transfer.create!(billing_profile: profile, hq_organization_id: "hq-usps-ops", amount_cents: 500, name: "t")) }
    expect(settled.destroy).to be(false)
    expect(settled.errors[:base]).to include("only pending entries can be deleted")
  end

  it "blocks destroying a ledgerable that has entries" do
    charge
    expect(batch.destroy).to be(false)
    expect(batch.errors[:base]).to include("cannot delete a record that has billing entries")
  end
end
