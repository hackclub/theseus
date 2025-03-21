class Warehouse::UpdateCancellationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    canceled_zenventory_orders = Zenventory
                                   .get_customer_orders(cancelled: true)
                                   .index_by { |order| order["orderNumber"] }
    Warehouse::Order.where(hc_id: canceled_zenventory_orders.keys).update_all(aasm_state: 'canceled')
  end
end
