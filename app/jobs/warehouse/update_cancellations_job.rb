class Warehouse::UpdateCancellationsJob < ApplicationJob
  queue_as :default

  good_job_control_concurrency_with(perform_limit: 1, key: "update_cancellations")

  def perform
    canceled_hc_ids = Zenventory
                        .get_customer_orders(cancelled: true)
                        .map { |order| order[:orderNumber].sub("hack.club/", "") }

    Warehouse::Order.where(hc_id: canceled_hc_ids).find_each do |order|
      next unless order.may_mark_canceled?
      order.mark_canceled!
    rescue => e
      Sentry.capture_exception(e, extra: { order_id: order.id }) if defined?(Sentry)
    end
  end
end
