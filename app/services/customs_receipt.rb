module CustomsReceipt
  class CustomsReceiptItem < Literal::Data
    prop :name, String
    prop :quantity, Integer
    prop :value, _Any
  end

  class CustomsReceiptable < Literal::Data
    prop :order_number, String
    prop :tracking_number, _String?
    prop :carrier, _String?
    prop :not_gifted, _Boolean, default: false
    prop :additional_info, _String?
    prop :contents, _Array(CustomsReceiptItem)
    prop :shipping_cost, _Any?
    prop :recipient_address, String

    def total_value
      contents.sum { |item| item.quantity * item.value }
    end
  end

  def mock_receiptable
    CustomsReceiptable.new(
      order_number: "pkg!sdfjkls",
      tracking_number: "9400182239154327",
      not_gifted: false,
      additional_info: "This package is nothing to worry about.",
      contents: [
        CustomsReceiptItem.new(
          name: "$30K in cash",
          quantity: 3,
          value: 30_000.99,
        ),
        CustomsReceiptItem.new(
          name: "*mysterious ticking noise...*",
          quantity: 1,
          value: 29.95,
        ),
      ],
      shipping_cost: 5.99,
      recipient_address: "ATTN: Director of Commercial Payment\nUS Postal Service\n475 L’Enfant Plz SW Rm 3436\nWashington DC 20260-4110\nUSA",
      carrier: "USPS",
    )
  end

  module_function :mock_receiptable
end
