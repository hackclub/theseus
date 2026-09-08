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
#
# Indexes
#
#  index_ledger_entries_on_billing_profile_id            (billing_profile_id)
#  index_ledger_entries_on_billing_profile_id_and_state  (billing_profile_id,state)
#  index_ledger_entries_on_category                      (category)
#  index_ledger_entries_on_hcb_transfer_id               (hcb_transfer_id)
#  index_ledger_entries_on_ledgerable                    (ledgerable_type,ledgerable_id)
#  index_ledger_entries_on_state                         (state)
#
# Foreign Keys
#
#  fk_rails_...  (billing_profile_id => hcb_payment_accounts.id)
#  fk_rails_...  (hcb_transfer_id => hcb_transfers.id)
#
class LedgerEntry < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :ledgerable, polymorphic: true
  belongs_to :hcb_transfer, class_name: "HCB::Transfer", optional: true

  enum :category, {
    labor: 0,
    postage: 1,
    contents: 2,
    indicia: 3,
  }

  enum :state, {
    pending: 0,
    settled: 1,
    failed: 2,
    refunded: 3,
  }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }

  scope :unsettled, -> { where(state: [:pending, :failed]) }
  scope :for_profile, ->(profile) { where(billing_profile: profile) }

  def settle!(transfer)
    update!(state: :settled, settled_at: Time.current, hcb_transfer: transfer)
  end

  def fail!
    update!(state: :failed)
  end

  def refund!(transfer)
    update!(state: :refunded, hcb_transfer: transfer)
  end

  def amount
    amount_cents / 100.0
  end
end
