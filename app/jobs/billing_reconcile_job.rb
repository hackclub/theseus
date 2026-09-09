class BillingReconcileJob < ApplicationJob
  queue_as :default

  good_job_control_concurrency_with(perform_limit: 1, key: "billing_reconcile")

  def perform
    results = Billing::Reconciler.run!
    return if results.empty?
    Rails.logger.info("[BillingReconcile] " + results.map { |r| "#{r.transfer.idempotency_key}=#{r.outcome}" }.join(", "))
  end
end
