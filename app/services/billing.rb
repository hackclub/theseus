# frozen_string_literal: true

# The only two ways money moves in Theseus:
#
#   Billing.charge!(entries, name:)                  org → HQ
#   Billing.credit!(reverses:, amount_cents:, name:) HQ → org
#
# Both create an HCB::Transfer row *before* talking to HCB and resolve it
# after, so every attempt leaves evidence. See HCB::Transfer for the state
# machine and Billing::Executor for how errors are classified.
module Billing
  class Error < StandardError; end
  # Another transfer for this profile is pending/unknown. Nothing was created.
  class InFlight < Error; end
  # The charge went out but HCB's answer was lost. Do not retry; do not
  # proceed with anything that assumes payment. Billing::Reconciler resolves it.
  class Unconfirmed < Error
    attr_reader :transfer
    def initialize(transfer) = (@transfer = transfer; super("charge #{transfer.idempotency_key} is awaiting confirmation from HCB"))
  end
  # HCB definitively rejected the transfer.
  class Rejected < Error
    attr_reader :transfer
    def initialize(transfer) = (@transfer = transfer; super(transfer.last_error.presence || "HCB rejected the transfer"))
  end

  # Claim unclaimed charge entries and move the money. Returns the transfer,
  # or nil if there was nothing to claim or (non-strict) another transfer is
  # in flight for the profile.
  #
  # strict: raise InFlight instead of returning nil; raise Unconfirmed /
  # Rejected instead of returning a non-completed transfer. Interactive
  # callers want strict; the sweep does not.
  def self.charge!(entries, name:, note: nil, execute: true, strict: false)
    Charge.new(entries, name: name, note: note, execute: execute, strict: strict).call
  end

  # One transfer per destination org (USPS postage and warehouse work are
  # paid into different HQ organizations). Returns the transfers created.
  def self.charge_pending!(billing_profile, name: "Theseus billing", note: nil)
    billing_profile.ledger_entries.unclaimed.charges
      .group_by { |e| destination_for(e.category) }
      .filter_map { |_, entries| charge!(entries, name: name, note: note) }
  end

  # Which HQ organization gets paid for a given kind of work.
  def self.destination_for(category)
    case category.to_s
    when "indicia" then ENV.fetch("HCB_USPS_ORG_ID")
    when "labor", "postage", "contents" then ENV.fetch("HCB_WAREHOUSE_ORG_ID")
    else raise ArgumentError, "no HCB destination for category #{category.inspect}"
    end
  end

  # Create a credit entry against `reverses` and send the money back.
  # Always strict: a refund the caller asked for either happens, is
  # unconfirmed, or is rejected — never silently skipped.
  def self.credit!(reverses:, amount_cents:, name:, note: nil, execute: true)
    Credit.new(reverses: reverses, amount_cents: amount_cents, name: name, note: note, execute: execute).call
  end

  def self.execute!(transfer, strict: false)
    Executor.new(transfer).call
    raise Unconfirmed.new(transfer) if strict && (transfer.unknown? || transfer.pending?)
    if strict && transfer.failed?
      transfer.abandon!
      # Credits auto-void here; charge entries are the caller's responsibility
      # (they may re-bill). Both current strict-charge callers void/destroy on
      # rescue Rejected — if you add a new one, don't forget.
      transfer.ledger_entries.pending.each { |e| e.void!(reason: transfer.last_error) } if transfer.credit?
      raise Rejected.new(transfer)
    end
    transfer
  end

  def self.in_flight?(billing_profile)
    billing_profile.hcb_transfers.where(state: [:pending, :unknown]).exists?
  end

  # Never in production: mock mode completes transfers without moving money.
  # config/initializers/billing.rb refuses to boot if it is set there anyway,
  # so this is belt and braces.
  def self.mock? = ENV["MOCK_HCB"].present? && !Rails.env.production?
end
