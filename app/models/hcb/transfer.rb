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
