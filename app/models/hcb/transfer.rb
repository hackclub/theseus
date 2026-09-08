# == Schema Information
#
# Table name: hcb_transfers
#
#  id                 :bigint           not null, primary key
#  amount_cents       :integer          not null
#  error_message      :string
#  state              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  billing_profile_id :bigint           not null
#  hcb_transaction_id :string
#
# Indexes
#
#  index_hcb_transfers_on_billing_profile_id  (billing_profile_id)
#  index_hcb_transfers_on_hcb_transaction_id  (hcb_transaction_id)
#  index_hcb_transfers_on_state               (state)
#
# Foreign Keys
#
#  fk_rails_...  (billing_profile_id => hcb_payment_accounts.id)
#
class HCB::Transfer < ApplicationRecord
  self.table_name = "hcb_transfers"

  belongs_to :billing_profile
  has_many :ledger_entries

  enum :state, {
    pending: 0,
    completed: 1,
    failed: 2,
  }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }

  def amount = amount_cents / 100.0

  def complete!(transaction_id)
    update!(state: :completed, hcb_transaction_id: transaction_id)
  end

  def fail!(message)
    update!(state: :failed, error_message: message)
  end

  def retry!
    raise "can only retry failed transfers" unless failed?
    update!(state: :pending, error_message: nil)
  end
end
