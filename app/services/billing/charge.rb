# frozen_string_literal: true

class Billing::Charge
  def initialize(entries, name:, memo:, execute:, strict:)
    @entries = entries
    @name = name
    @memo = memo
    @execute = execute
    @strict = strict
  end

  def call
    transfer = claim!
    return nil unless transfer
    return transfer unless @execute

    Billing.execute!(transfer, strict: @strict)
  end

  private

  # Phase 1: inside one transaction, lock the profile (serialises the
  # in-flight check), lock the entries (SKIP LOCKED so a concurrent sweep
  # just sees fewer), create the pending transfer, and claim.
  def claim!
    ActiveRecord::Base.transaction do
      ids = @entries.respond_to?(:pluck) ? @entries.pluck(:id) : @entries.map(&:id)
      entries = LedgerEntry.where(id: ids)
        .lock("FOR UPDATE SKIP LOCKED")
        .unclaimed.charges
        .to_a
      return nil if entries.empty?

      profile_ids = entries.map(&:billing_profile_id).uniq
      raise ArgumentError, "entries span multiple billing profiles" if profile_ids.size > 1
      destinations = entries.map { |e| Billing.destination_for(e.category) }.uniq
      raise ArgumentError, "entries span multiple HCB destinations (#{destinations.join(", ")}); charge them separately" if destinations.size > 1
      profile = BillingProfile.lock.find(profile_ids.first)

      if Billing.in_flight?(profile)
        raise Billing::InFlight, "#{profile.organization_name} has a transfer awaiting confirmation" if @strict
        return nil
      end

      transfer = HCB::Transfer.create!(
        billing_profile: profile,
        direction: :debit,
        hq_organization_id: destinations.first,
        amount_cents: entries.sum(&:amount_cents),
        name: @name,
        memo: @memo || default_memo(entries),
        metadata: { "ledger_entry_ids" => entries.map(&:id) },
      )
      LedgerEntry.where(id: entries.map(&:id)).update_all(hcb_transfer_id: transfer.id)
      transfer
    end
  end

  def default_memo(entries)
    lines = entries.map { |e| "#{e.category} #{e.ledgerable_type.demodulize.downcase}##{e.ledgerable_id} $#{"%.2f" % e.amount}" }
    "[theseus] #{lines.join(", ")}"
  end
end
