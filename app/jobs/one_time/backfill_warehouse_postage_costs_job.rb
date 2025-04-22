class OneTime::BackfillWarehousePostageCostsJob < ApplicationJob
  queue_as :default

  FUDGE_FACTOR = 4.weeks

  def perform(*args)
    orders = Warehouse::Order.mailed.order(mailed_at: :asc)

    return if orders.empty?

    start_date = orders.first.dispatched_at - FUDGE_FACTOR
    end_date = orders.last.dispatched_at + FUDGE_FACTOR

    zen_orders = Zenventory.run_report(
      "shipment",
      "ship_client",
      startDate: start_date,
      endDate: end_date
    ).index_by { |order| order[:order_number].sub("hack.club/", "") }

    orders.each do |order|
      zen_order = zen_orders[order.hc_id]
      next unless zen_order
      order.update(
        postage_cost: zen_order[:shipping_handling],
      )
    end
  end
end
