module Ledgerable
  extend ActiveSupport::Concern

  included do
    has_many :ledger_entries, as: :ledgerable, dependent: :nullify

    # Prevent destruction of records that have settled/refunded billing entries
    before_destroy :prevent_destroy_with_settled_entries

    # Records that have a billing profile but no ledger entries at all.
    # Useful for sweep jobs that catch things that fell through the cracks.
    scope :unbilled, -> {
      left_joins(:ledger_entries)
        .where(ledger_entries: { id: nil })
    }
  end

  def total_billed_cents
    ledger_entries.where.not(state: :refunded).sum(:amount_cents)
  end

  def total_settled_cents
    ledger_entries.settled.sum(:amount_cents)
  end

  def billing_settled?
    ledger_entries.unsettled.none?
  end

  private

  def prevent_destroy_with_settled_entries
    if ledger_entries.where(state: [:settled, :refunded]).exists?
      errors.add(:base, "cannot delete a record with settled billing entries")
      throw(:abort)
    end
  end
end
