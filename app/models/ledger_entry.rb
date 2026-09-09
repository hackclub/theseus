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
# A ledger entry is an obligation: "this billing profile owes (or is owed)
# this many cents for this thing". Entries are append-only. A positive
# amount is a charge; a negative amount is a credit that `reverses` an
# earlier charge. Amount, category, ledgerable and profile never change
# after creation — the only thing that moves is `state`, which tracks
# whether the money for this entry has actually moved via an HCB::Transfer.
#
#   pending → settled   money moved (hcb_transfer completed)
#   pending → voided    obligation cancelled before any money moved
#
class LedgerEntry < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :ledgerable, polymorphic: true
  belongs_to :hcb_transfer, class_name: "HCB::Transfer", optional: true
  belongs_to :reverses, class_name: "LedgerEntry", optional: true
  has_many :reversals, class_name: "LedgerEntry", foreign_key: :reverses_id, dependent: :restrict_with_error

  attr_readonly :amount_cents, :category, :ledgerable_type, :ledgerable_id, :billing_profile_id, :reverses_id

  enum :category, {
    labor: 0,
    postage: 1,
    contents: 2,
    indicia: 3
  }

  enum :state, {
    pending: 0,
    settled: 1,
    voided: 2
  }

  validates :amount_cents, presence: true, numericality: { other_than: 0, only_integer: true }
  validate :credit_reverses_a_charge, on: :create
  before_destroy :only_pending_can_be_destroyed

  scope :charges, -> { where("amount_cents > 0") }
  scope :credits, -> { where("amount_cents < 0") }
  scope :live, -> { where.not(state: :voided) }
  scope :unclaimed, -> { pending.where(hcb_transfer_id: nil) }
  scope :for_profile, ->(profile) { where(billing_profile: profile) }

  def charge? = amount_cents.positive?
  def credit? = amount_cents.negative?

  def amount
    amount_cents / 100.0
  end

  # Net amount of this charge after any settled/pending credits against it.
  def net_cents
    amount_cents + reversals.live.sum(:amount_cents)
  end

  def settle!(transfer)
    raise ArgumentError, "can only settle a pending entry" unless pending?
    update!(state: :settled, settled_at: Time.current, hcb_transfer: transfer)
  end

  def void!(reason: nil)
    raise ArgumentError, "can only void a pending entry" unless pending?
    raise ArgumentError, "entry is claimed by transfer #{hcb_transfer.idempotency_key} (#{hcb_transfer.state}); abandon it first" if hcb_transfer&.holds_entries?
    update!(state: :voided, metadata: metadata.merge("voided_reason" => reason).compact)
  end

  private

  # A pending entry never moved money, so deleting it loses nothing. Anything
  # else is history.
  def only_pending_can_be_destroyed
    if !pending?
      errors.add(:base, "only pending entries can be deleted")
      throw(:abort)
    elsif hcb_transfer&.holds_entries?
      errors.add(:base, "entry is claimed by transfer #{hcb_transfer.idempotency_key} (#{hcb_transfer.state})")
      throw(:abort)
    end
  end

  def credit_reverses_a_charge
    return unless credit?
    return errors.add(:reverses, "is required for a credit") if reverses.nil?
    errors.add(:reverses, "must be a charge") unless reverses.charge?
    errors.add(:reverses, "must be on the same billing profile") if reverses.billing_profile_id != billing_profile_id
    if reverses.settled? && (reverses.net_cents + amount_cents).negative?
      errors.add(:amount_cents, "would credit more than was charged")
    end
  end
end
