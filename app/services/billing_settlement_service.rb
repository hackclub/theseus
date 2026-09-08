class BillingSettlementService
  attr_reader :billing_profile, :errors

  def initialize(billing_profile:, entries: nil)
    @billing_profile = billing_profile
    @explicit_entries = entries
    @errors = []
  end

  # Settle all pending entries for this billing profile in one HCB transfer.
  # Uses SELECT FOR UPDATE to prevent double-charging from concurrent calls.
  def settle!
    settled = false

    ActiveRecord::Base.transaction do
      # Lock the pending entries so no other process can settle them concurrently.
      # If explicit entries were passed, lock those; otherwise find all pending for this profile.
      entries = if @explicit_entries
        LedgerEntry.where(id: @explicit_entries.map(&:id))
          .lock("FOR UPDATE SKIP LOCKED")
          .pending
          .to_a
      else
        billing_profile.ledger_entries
          .lock("FOR UPDATE SKIP LOCKED")
          .pending
          .to_a
      end

      return true if entries.none?

      total_cents = entries.sum(&:amount_cents)
      return true if total_cents <= 0

      # Create the transfer record inside the transaction
      hcb_transfer = HCB::Transfer.create!(
        billing_profile: billing_profile,
        amount_cents: total_cents,
        state: :pending,
      )

      # Associate entries with this transfer before we leave the lock
      LedgerEntry.where(id: entries.map(&:id)).update_all(hcb_transfer_id: hcb_transfer.id)

      memo_lines = entries.map { |e| "#{e.category}: #{e.ledgerable_type}##{e.ledgerable_id} ($#{"%.2f" % e.amount})" }
      memo = "[theseus] #{memo_lines.join(", ")}"

      transfer_service = HCB::TransferService.new(
        billing_profile: billing_profile,
        amount_cents: total_cents,
        name: "Theseus billing: #{entries.count} entries",
        memo: memo.truncate(500),
      )

      result = transfer_service.call

      if result
        transaction_id = result.respond_to?(:id) ? result.id : result.try(:transaction_id) || result.to_s
        hcb_transfer.complete!(transaction_id)
        LedgerEntry.where(id: entries.map(&:id)).update_all(
          state: LedgerEntry.states[:settled],
          settled_at: Time.current,
        )
        settled = true
      else
        error_msg = transfer_service.errors.join("; ")
        hcb_transfer.fail!(error_msg)
        LedgerEntry.where(id: entries.map(&:id)).update_all(
          state: LedgerEntry.states[:failed],
        )

        is_insufficient = transfer_service.errors.any? { |e| e.include?("insufficient") || e.include?("Insufficient") }

        mailer_params = {
          ledger_entries: entries,
          billing_profile: billing_profile,
          error: error_msg,
        }

        if is_insufficient
          BillingMailer.with(mailer_params).insufficient_funds.deliver_later
        else
          BillingMailer.with(mailer_params).settlement_failed.deliver_later
        end

        @errors = transfer_service.errors
        settled = false
      end
    end

    settled
  end

  # Settle all pending entries across ALL billing profiles (for sweep job).
  def self.settle_all!
    results = { settled: 0, failed: 0 }

    BillingProfile.joins(:ledger_entries)
      .merge(LedgerEntry.pending)
      .distinct
      .find_each do |profile|
        service = new(billing_profile: profile)
        if service.settle!
          results[:settled] += 1
        else
          results[:failed] += 1
        end
      end

    results
  end
end
