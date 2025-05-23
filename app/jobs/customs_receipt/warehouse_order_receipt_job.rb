class CustomsReceipt::WarehouseOrderReceiptJob < ApplicationJob
  queue_as :default

  def perform(warehouse_order_id)
    order = Warehouse::Order.find(warehouse_order_id)

    receiptable = CustomsReceipt::TheseusSpecific.receiptable_from_warehouse_order(order)
    pdf = CustomsReceipt::Generate.run(receiptable)

    # Send the email with PDF attachment
    CustomsReceipt::ReceiptMailer.with(
      email: order.recipient_email,
      order_number: order.hc_id,
      pdf_data: pdf,
    ).receipt.deliver_now
  end
end
