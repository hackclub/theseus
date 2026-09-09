# == Schema Information
#
# Table name: hcb_transfers
#
#  id                 :bigint           not null, primary key
#  amount_cents       :integer          not null
#  attempts           :integer          default(0), not null
#  direction          :integer          default(0), not null
#  idempotency_key    :string           not null
#  last_attempted_at  :datetime
#  last_error         :string
#  memo               :text
#  metadata           :jsonb
#  name               :string
#  next_attempt_at    :datetime
#  state              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  billing_profile_id :bigint           not null
#  hq_organization_id :string           not null
#  remote_id          :string
#
# Indexes
#
#  index_hcb_transfers_on_billing_profile_id         (billing_profile_id)
#  index_hcb_transfers_on_hq_organization_id         (hq_organization_id)
#  index_hcb_transfers_on_idempotency_key            (idempotency_key) UNIQUE
#  index_hcb_transfers_on_remote_id                  (remote_id)
#  index_hcb_transfers_on_state                      (state)
#  index_hcb_transfers_on_state_and_next_attempt_at  (state,next_attempt_at)
#
# Foreign Keys
#
#  fk_rails_...  (billing_profile_id => hcb_payment_accounts.id)
#
# One attempt to move money between an HCB organization and Theseus.
# The row exists *before* the API call is made and is resolved after, so a
# crash at any point leaves evidence. `idempotency_key` is embedded in the
# disbursement name so Billing::Reconciler can find it on HCB's side later.
#
#   pending   → created, not yet sent (or sent, crashed before resolution)
#   completed → HCB confirmed; remote_id set
#   failed    → HCB definitively rejected; may be retried (next_attempt_at)
#   unknown   → request went out but we can't prove the outcome. Never
#               auto-retried. Billing::Reconciler resolves it.
#
class HCB::Transfer < ApplicationRecord
  self.table_name = "hcb_transfers"

  MAX_ATTEMPTS = 5
  STALE_PENDING_AFTER = 10.minutes

  belongs_to :billing_profile
  has_many :ledger_entries, foreign_key: :hcb_transfer_id, inverse_of: :hcb_transfer

  enum :direction, {
    debit: 0,   # billing profile's org → theseus (a charge)
    credit: 1,  # theseus → billing profile's org (a refund)
  }

  enum :state, {
    pending: 0,
    completed: 1,
    failed: 2,
    unknown: 3,
  }

  validates :amount_cents, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :idempotency_key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :hq_organization_id, presence: true

  before_validation :generate_idempotency_key, on: :create

  scope :due_for_retry, -> { failed.where(next_attempt_at: ..Time.current) }
  scope :stale_pending, -> { pending.where(last_attempted_at: ..STALE_PENDING_AFTER.ago) }
  scope :needs_reconciliation, -> { unknown.or(stale_pending) }

  def amount = amount_cents / 100.0

  # The name as sent to HCB — the key is what lets us find it again.
  def tagged_name = "#{name} [#{idempotency_key}]"

  def resolved? = completed? || (failed? && next_attempt_at.nil?)
  def retryable? = failed? && next_attempt_at.present?
  def gave_up? = failed? && next_attempt_at.nil? && attempts >= MAX_ATTEMPTS

  def begin_attempt!
    update!(attempts: attempts + 1, last_attempted_at: Time.current, state: :pending)
  end

  # Two separate writes on purpose: the remote id is the one fact we must
  # never lose. If settling the entries fails, the transfer is still
  # completed and BillingSettlementSweepJob#repair_settlements! finishes it.
  def complete!(remote_id)
    update!(state: :completed, remote_id: remote_id, next_attempt_at: nil, last_error: nil)
    settle_entries!
  end

  def settle_entries!
    raise "transfer is not completed" unless completed?
    ledger_entries.pending.find_each { |e| e.settle!(self) }
  end

  scope :with_unsettled_entries, -> {
    completed.where(id: LedgerEntry.pending.where.not(hcb_transfer_id: nil).select(:hcb_transfer_id))
  }

  def fail!(message, retryable: true)
    next_at = retryable && attempts < MAX_ATTEMPTS ? backoff.from_now : nil
    update!(state: :failed, last_error: message.to_s.truncate(255), next_attempt_at: next_at)
  end

  def mark_unknown!(message)
    update!(state: :unknown, last_error: message.to_s.truncate(255), next_attempt_at: nil)
  end

  # Manual retry from admin: reset the clock, keep the key.
  def retry!
    raise "can only retry failed or unknown transfers" unless failed? || unknown?
    update!(state: :failed, attempts: 0, next_attempt_at: Time.current, last_error: nil)
  end

  private

  # 15m, 30m, 1h, 2h, 4h
  def backoff = (15 * (2**(attempts - 1))).clamp(15, 240).minutes

  def generate_idempotency_key
    self.idempotency_key ||= "th_#{SecureRandom.alphanumeric(12)}"
  end
end
