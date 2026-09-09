# frozen_string_literal: true

# Buy postage for one letter, paid for by one billing profile. Used by the
# single-letter UI and instant queues. (Batches charge once per batch in
# BatchProcessJob and only use the buy step.)
#
#   1. lock the letter; create the indicium if needed
#   2. charge HCB for the estimated postage (skipped if already settled)
#   3. buy from USPS
#   4. if USPS provably didn't sell us anything, credit the charge back
#
# Nothing external happens inside a DB transaction.
class USPS::IndiciumPurchase
  class AlreadyPurchased < StandardError; end
  # USPS sold us postage but we couldn't record it. Money and postage both
  # moved; do NOT refund. Needs a human.
  class Unrecorded < StandardError
    attr_reader :indicium, :cause_error
    def initialize(indicium, cause_error) = (@indicium = indicium; @cause_error = cause_error; super("postage was purchased but failed to save: #{cause_error.message}"))
  end
  # USPS purchase failed before anything was sold; the charge was credited back
  # (or attempted to be — see `credit`).
  class PurchaseFailed < StandardError
    attr_reader :cause_error, :credit
    def initialize(cause_error, credit) = (@cause_error = cause_error; @credit = credit; super(cause_error.message))
    def refunded? = credit&.completed?
  end

  attr_reader :letter, :usps_account, :billing_profile, :indicium

  def initialize(letter:, usps_account:, billing_profile:, payment_token: nil, mailing_date: nil, name_suffix: nil)
    @letter = letter
    @usps_account = usps_account
    @billing_profile = billing_profile
    @payment_token = payment_token
    @mailing_date = mailing_date || letter.mailing_date
    @name_suffix = name_suffix
  end

  def call
    @indicium = find_or_create_indicium
    charge = ensure_charged!
    buy!(charge)
    indicium.reload
  end

  private

  def find_or_create_indicium
    letter.with_lock do
      existing = letter.usps_indicium
      raise AlreadyPurchased, "Indicia already purchased for this letter." if existing&.postage.present?
      existing || USPS::Indicium.create!(
        letter: letter,
        payment_account: usps_account,
        billing_profile: billing_profile,
        mailing_date: @mailing_date,
      )
    end
  end

  def ensure_charged!
    existing = indicium.ledger_entries.indicia.charges.live.order(:id).last
    return existing if existing&.settled?
    raise Billing::Unconfirmed.new(existing.hcb_transfer) if existing&.pending? && existing.hcb_transfer&.unknown?

    entry = existing || indicium.ledger_entries.create!(
      billing_profile: billing_profile,
      category: :indicia,
      amount_cents: Billing::Quote.new(letter.billing_lines).now_cents,
    )

    begin
      transfer = Billing.charge!([ entry ], name: charge_name, note: "#{letter.processing_category}#{@name_suffix}", strict: true)
      # nil: the entry is already claimed by an earlier attempt (failed and
      # waiting for backoff, or still in flight). Settle that one now rather
      # than buying postage against money that never moved.
      Billing.execute!(entry.reload.hcb_transfer, strict: true) if transfer.nil?

    rescue Billing::Rejected, Billing::InFlight
      # Nothing moved. Don't leave a half-built indicium on the letter; the
      # failed HCB::Transfer row is the record that we tried.
      entry.reload.destroy! if entry.pending?
      indicium.ledger_entries.reset
      indicium.destroy! if indicium.ledger_entries.none? && indicium.postage.blank?
      raise
    end
    entry.reload
  end

  def buy!(charge)
    indicium.buy!(@payment_token)
  rescue => e
    if indicium.raw_json_response.present?
      Sentry.capture_exception(e, level: :fatal, tags: { money: true, critical: true },
        extra: { indicium_id: indicium.id, letter_id: letter.id, response: indicium.raw_json_response })
      raise Unrecorded.new(indicium, e)
    end

    credit = begin
      Billing.credit!(reverses: charge, amount_cents: charge.net_cents, name: "Refund for #{letter.public_id} #{indicium.public_id}",
        note: "USPS purchase failed: #{e.message.truncate(120)}")
    rescue Billing::Error => credit_error
      Sentry.capture_exception(credit_error, tags: { money: true }, extra: { indicium_id: indicium.id }) if defined?(Sentry)
      credit_error.try(:transfer)
    end
    raise PurchaseFailed.new(e, credit)
  end

  def charge_name
    "Postage for #{letter.public_id} #{indicium.public_id} #{Rails.application.routes.url_helpers.letter_path(letter)}"
  end
end
