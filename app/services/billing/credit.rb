# frozen_string_literal: true

class Billing::Credit
  def initialize(reverses:, amount_cents:, name:, note:, execute:)
    @reverses = reverses
    @amount_cents = amount_cents.to_i
    @name = name
    @note = note
    @execute = execute
  end

  def call
    raise ArgumentError, "credit amount must be positive" unless @amount_cents.positive?

    transfer = ActiveRecord::Base.transaction do
      profile = BillingProfile.lock.find(@reverses.billing_profile_id)
      original = LedgerEntry.lock.find(@reverses.id)
      raise ArgumentError, "can only credit a settled charge" unless original.charge? && original.settled?
      raise Billing::InFlight, "#{profile.organization_name} has a transfer awaiting confirmation" if Billing.in_flight?(profile)
      if @amount_cents > original.net_cents
        raise ArgumentError, "cannot credit $#{"%.2f" % (@amount_cents / 100.0)}; only $#{"%.2f" % (original.net_cents / 100.0)} remains on that charge"
      end

      entry = LedgerEntry.create!(
        billing_profile: profile,
        ledgerable: original.ledgerable,
        category: original.category,
        amount_cents: -@amount_cents,
        reverses: original,
      )
      HCB::Transfer.create!(
        billing_profile: profile,
        direction: :credit,
        hq_organization_id: original.hcb_transfer&.hq_organization_id || Billing.destination_for(original.category),
        amount_cents: @amount_cents,
        name: @name,
        memo: Billing::Memo.credit(entry, original, note: @note),
        metadata: { "ledger_entry_ids" => [ entry.id ] },

      ).tap { |t| entry.update!(hcb_transfer: t) }
    end

    return transfer unless @execute
    Billing.execute!(transfer, strict: true)
  end
end
