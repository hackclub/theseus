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

  # Net of charges and credits, excluding voided entries.
  def total_billed_cents(category = nil)
    scoped_entries(category).live.sum(:amount_cents)
  end

  def total_charged_cents(category = nil)
    scoped_entries(category).live.charges.sum(:amount_cents)
  end

  def total_credited_cents(category = nil)
    -scoped_entries(category).live.credits.sum(:amount_cents)
  end

  def total_settled_cents(category = nil)
    scoped_entries(category).settled.sum(:amount_cents)
  end

  def billing_settled?
    ledger_entries.pending.none?
  end

  private

  def scoped_entries(category)
    category ? ledger_entries.where(category: category) : ledger_entries
  end

  def prevent_destroy_with_billing_entries
    if ledger_entries.exists?
      errors.add(:base, "cannot delete a record that has billing entries")
      throw(:abort)
    end
  end
end
