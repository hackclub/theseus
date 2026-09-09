# Every 15 minutes:
#  1. anything left unclaimed (batch postage, orders whose immediate charge
#     was skipped because a transfer was in flight) gets charged per profile
#  2. failed transfers whose backoff has elapsed are re-executed
#  3. completed transfers whose entries were never settled get repaired
class BillingSettlementSweepJob < ApplicationJob
  queue_as :default

  good_job_control_concurrency_with(perform_limit: 1, key: "billing_settlement_sweep")

  def perform
    charged = 0
    BillingProfile.where(id: LedgerEntry.unclaimed.charges.select(:billing_profile_id)).find_each do |profile|
      transfer = Billing.charge_pending!(profile)
      charged += 1 if transfer
    rescue => e
      Sentry.capture_exception(e, extra: { billing_profile_id: profile.id }) if defined?(Sentry)
    end

    retried = 0
    HCB::Transfer.due_for_retry.find_each do |transfer|
      Billing.execute!(transfer)
      retried += 1
    rescue => e
      Sentry.capture_exception(e, extra: { transfer_id: transfer.id }) if defined?(Sentry)
    end

    repaired = repair_settlements!

    Rails.logger.info("[BillingSettlementSweep] charged: #{charged}, retried: #{retried}, repaired: #{repaired}")
  end

  # A transfer completed on HCB but we crashed before settling its entries.
  def repair_settlements!
    HCB::Transfer.with_unsettled_entries.find_each.sum do |transfer|
      transfer.settle_entries!
      1
    rescue => e
      Sentry.capture_exception(e, extra: { transfer_id: transfer.id }) if defined?(Sentry)
      0
    end
  end
end
