class Warehouse::UpdateCancellationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    canceled_zenventory_orders = Zenventory
                                   .get_customer_orders(cancelled: true)
                                   .map { |order| order[:orderNumber].sub("hack.club/", "") }
    Warehouse::Order.where(hc_id: canceled_zenventory_orders).update_all(aasm_state: "canceled")
  end
end
