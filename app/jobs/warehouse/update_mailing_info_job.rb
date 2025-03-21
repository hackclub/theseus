class Warehouse::UpdateMailingInfoJob < ApplicationJob
  queue_as :default

  FUDGE_FACTOR = 2.weeks

  def perform(*args)
    orders = Warehouse::Order.dispatched.order(dispatched_at: :asc)

    start_date = orders.first.dispatched_at - FUDGE_FACTOR
    end_date = orders.last.dispatched_at + FUDGE_FACTOR

    zen_orders = Zenventory.run_report(
      "shipment",
      "ship_client",
      startDate: start_date,
      endDate: end_date
    ).index_by { |order| order[:order_number] }

    orders.each do |order|
      zen_order = zen_orders[order.hc_id]
      next unless zen_order
      order.update(
        carrier: zen_order[:carrier],
        service: zen_order[:service],
        weight: zen_order[:weight],
        tracking_number: zen_order[:tracking_number],
        mailed_at: DateTime.parse(zen_order[:shipped_date]),
        aasm_state: "mailed"
      )
    end
  end
end
