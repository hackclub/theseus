class Warehouse::UpdateMailingInfoJob < ApplicationJob
  queue_as :default

  FUDGE_FACTOR = 2.weeks

  def perform(*args)
    orders = Warehouse::Order.dispatched.order(dispatched_at: :asc)

    return if orders.empty?

    start_date = orders.first.dispatched_at - FUDGE_FACTOR
    end_date = orders.last.dispatched_at + FUDGE_FACTOR

    zen_orders = Zenventory.run_report(
      "shipment",
      "ship_client",
      startDate: start_date,
      endDate: end_date
    ).index_by { |order| order[:order_number].to_s.sub("hack.club/", "") }

    # Track which billing profiles need settlement after processing
    profiles_to_settle = Set.new

    orders.each do |order|
      zen_order = zen_orders[order.hc_id]
      next unless zen_order
      order.update(
        carrier: zen_order[:carrier],
        service: zen_order[:service],
        weight: zen_order[:weight],
        tracking_number: zen_order[:tracking_number],
        mailed_at: DateTime.parse(zen_order[:shipped_date]),
        postage_cost: zen_order[:shipping_handling],
        aasm_state: "mailed"
      )
      Warehouse::OrderMailer.with(order:).order_shipped.deliver_later

      # Create postage ledger entry if billing profile is present and postage is known
      if order.billing_profile.present? && zen_order[:shipping_handling].to_d.positive?
        order.ledger_entries.create!(
          billing_profile: order.billing_profile,
          category: :postage,
          amount_cents: (zen_order[:shipping_handling].to_d * 100).ceil,
        )
        profiles_to_settle << order.billing_profile
      end
    end

    # Settle each billing profile that had new postage entries
    profiles_to_settle.each do |profile|
      BillingSettlementService.new(billing_profile: profile).settle!
    end
  end
end
