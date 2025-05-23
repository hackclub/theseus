module CustomsReceipt
  module TheseusSpecific
    class << self
      def receiptable_from_zenventory_order(
        order:,
        order_number:,
        tracking_number:,
        carrier:,
        shipping_cost:,
        not_gifted: false,
        additional_info: nil
      )
        CustomsReceiptable.new(
          order_number:,
          tracking_number:,
          carrier:,
          not_gifted: false,
          additional_info:,
          contents: order.dig(:items)&.map do |item|
            price = item.dig(:price)
            CustomsReceiptItem.new(
              name: item.dig(:description),
              quantity: item.dig(:quantity),
              value: (price != 0.0 ? price : Warehouse::SKU.find_by(sku: item.dig(:sku))&.declared_unit_cost.to_f) || 1.0,
            )
          end,
          shipping_cost:,
          recipient_address: [
            "#{order.dig(:shippingAddress, :name)}",
            order.dig(:shippingAddress, :line1),
            order.dig(:shippingAddress, :line2),
            "#{order.dig(:shippingAddress, :city)}, #{order.dig(:shippingAddress, :state)} #{order.dig(:shippingAddress, :zip)}",
            order.dig(:shippingAddress, :country),
          ].compact_blank.join("\n"),
        )
      end

      def receiptable_from_warehouse_order(order)
        zenv = Zenventory.get_customer_order(order.zenventory_id)
        additional_info = nil

        receiptable_from_zenventory_order(
          order: zenv,
          order_number: order.hc_id,
          tracking_number: order.tracking_number,
          carrier: order.carrier,
          shipping_cost: order.postage_cost,
          additional_info:,
        )
      end

      def receiptable_from_msr(msr)
        zenv = Zenventory.order_by_hc_id(msr.source_id)
        additional_info = nil

        puts msr["Request Type"]
        if msr["Request Type"]&.include? "High Seas"
          additional_info = 'This shipment was sent out as part of <a href="https://highseas.hackclub.com">High Seas</a>, a grant program that rewards students for time spent programming.'
        end

        receiptable_from_zenventory_order(
          order: zenv,
          order_number: msr.source_id,
          tracking_number: msr["Warehouse–Tracking Number"],
          carrier: msr["Warehouse–Service"],
          shipping_cost: msr["Warehouse–Postage Cost"]&.to_f,
          additional_info:,
        )
      end
    end
  end
end
