module Ledgerable
  extend ActiveSupport::Concern

  included do
    # Guard must be declared BEFORE has_many so its callback runs first
    before_destroy :prevent_destroy_with_billing_entries

    has_many :ledger_entries, as: :ledgerable, dependent: :restrict_with_error
    # dependent: :restrict_with_error means:
    # - if any entries exist, destroy is blocked with a validation error
    # - entries are never orphaned or cascade-deleted
    # - to destroy a billable, its entries must be explicitly handled first

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

  def prevent_destroy_with_billing_entries
    if ledger_entries.exists?
      errors.add(:base, "cannot delete a record that has billing entries")
      throw(:abort)
    end
  end
end
