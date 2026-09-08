class LedgerEntry < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :ledgerable, polymorphic: true

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

  def settle!(transfer_id)
    update!(state: :settled, settled_at: Time.current, hcb_transfer_id: transfer_id)
  end

  def fail!
    update!(state: :failed)
  end

  def refund!(transfer_id)
    update!(state: :refunded, hcb_transfer_id: transfer_id)
  end

  def amount
    amount_cents / 100.0
  end
end
