class BillingSettlementService
  attr_reader :billing_profile, :errors

  MAX_RETRY_ATTEMPTS = 5

  def initialize(billing_profile:, entries: nil)
    @billing_profile = billing_profile
    @explicit_entries = entries
    @errors = []
  end

  # Settle pending entries in two phases:
  # Phase 1 (DB tx): lock UNCLAIMED entries, create pending transfer, claim them
  # Phase 2 (no tx): call HCB API
  # Phase 3 (DB tx): mark settled or failed
  def settle!
    hcb_transfer = nil
    entry_ids = nil
    total_cents = nil

    # Phase 1: claim entries inside a transaction
    ActiveRecord::Base.transaction do
      entries = if @explicit_entries
        LedgerEntry.where(id: @explicit_entries.map(&:id))
          .lock("FOR UPDATE SKIP LOCKED")
          .where(state: :pending, hcb_transfer_id: nil)  # only unclaimed entries
          .to_a
      else
        billing_profile.ledger_entries
          .lock("FOR UPDATE SKIP LOCKED")
          .where(state: :pending, hcb_transfer_id: nil)  # only unclaimed entries
          .to_a
      end

      return true if entries.none?

      total_cents = entries.sum(&:amount_cents)
      return true if total_cents <= 0

      entry_ids = entries.map(&:id)

      # Create pending transfer and claim entries — survives even if HCB call crashes
      hcb_transfer = HCB::Transfer.create!(
        billing_profile: billing_profile,
        amount_cents: total_cents,
        state: :pending,
      )
      LedgerEntry.where(id: entry_ids).update_all(hcb_transfer_id: hcb_transfer.id)
    end

    # Bail if nothing was claimed
    return true unless hcb_transfer

    # Phase 2: call HCB outside any transaction
    memo_entries = LedgerEntry.where(id: entry_ids)
    memo_lines = memo_entries.map { |e| "#{e.category}: #{e.ledgerable_type}##{e.ledgerable_id} ($#{"%.2f" % e.amount})" }
    memo = "[theseus] #{memo_lines.join(", ")}"

    transfer_service = HCB::TransferService.new(
      billing_profile: billing_profile,
      amount_cents: total_cents,
      name: "Theseus billing: #{entry_ids.size} entries",
      memo: memo.truncate(500),
    )

    result = transfer_service.call

    # Phase 3: finalize in a new transaction
    if result
      transaction_id = result.respond_to?(:id) ? result.id : result.try(:transaction_id) || result.to_s
      ActiveRecord::Base.transaction do
        hcb_transfer.complete!(transaction_id)
        LedgerEntry.where(id: entry_ids).update_all(
          state: LedgerEntry.states[:settled],
          settled_at: Time.current,
        )
      end
      true
    else
      error_msg = transfer_service.errors.join("; ")
      ActiveRecord::Base.transaction do
        hcb_transfer.fail!(error_msg)
        LedgerEntry.where(id: entry_ids).update_all(
          state: LedgerEntry.states[:failed],
          hcb_transfer_id: nil,  # unclaim so they can be retried
        )
      end

      is_insufficient = transfer_service.errors.any? { |e| e.include?("insufficient") || e.include?("Insufficient") }
      mailer_params = {
        ledger_entries: LedgerEntry.where(id: entry_ids).to_a,
        billing_profile: billing_profile,
        error: error_msg,
      }

      if is_insufficient
        BillingMailer.with(mailer_params).insufficient_funds.deliver_later
      else
        BillingMailer.with(mailer_params).settlement_failed.deliver_later
      end

      @errors = transfer_service.errors
      false
    end
  end

  # Settle unclaimed pending entries across ALL billing profiles.
  # Also retries failed entries up to MAX_RETRY_ATTEMPTS.
  def self.settle_all!
    results = { settled: 0, failed: 0, errors: [] }

    # Retry failed entries that haven't exceeded max attempts
    LedgerEntry.failed
      .where(hcb_transfer_id: nil)
      .where("(metadata->>'retry_count')::int < ? OR metadata->>'retry_count' IS NULL", MAX_RETRY_ATTEMPTS)
      .find_each do |entry|
        count = (entry.metadata["retry_count"] || 0).to_i + 1
        entry.update_columns(
          state: LedgerEntry.states[:pending],
          metadata: entry.metadata.merge("retry_count" => count),
        )
      end

    BillingProfile.joins(:ledger_entries)
      .merge(LedgerEntry.where(state: :pending, hcb_transfer_id: nil))
      .distinct
      .find_each do |profile|
        begin
          service = new(billing_profile: profile)
          if service.settle!
            results[:settled] += 1
          else
            results[:failed] += 1
          end
        rescue => e
          results[:errors] << "#{profile.id}: #{e.message}"
          Sentry.capture_exception(e, extra: { billing_profile_id: profile.id }) if defined?(Sentry)
        end
      end

    results
  end
end
