class BillingSettlementSweepJob < ApplicationJob
  queue_as :default

  def perform
    results = BillingSettlementService.settle_all!
    Rails.logger.info("[BillingSettlementSweep] settled: #{results[:settled]}, failed: #{results[:failed]}")
  end
end
