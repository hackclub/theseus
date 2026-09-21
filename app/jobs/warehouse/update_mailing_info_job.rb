class Warehouse::UpdateMailingInfoJob < ApplicationJob
  queue_as :default

  good_job_control_concurrency_with(perform_limit: 1, key: "update_mailing_info")

  FUDGE_FACTOR = 2.weeks

  def perform(*args)
    orders = Warehouse::Order.dispatched

    return unless orders.exists?

    start_date = orders.minimum(:dispatched_at) - FUDGE_FACTOR
    end_date = orders.maximum(:dispatched_at) + FUDGE_FACTOR

    zen_orders = Zenventory.run_report(
      "shipment",
      "ship_client",
      startDate: start_date,
      endDate: end_date
    ).index_by { |order| order[:order_number].to_s.sub("hack.club/", "") }

    # Individual orders are charged as soon as postage is known; bulk-upload
    # orders are left unclaimed for the sweep to batch per profile.
    orders_to_charge = []

    orders.find_each do |order|
      zen_order = zen_orders[order.hc_id]
      next unless zen_order

      # Lock the order to prevent concurrent job runs from double-processing
      order.with_lock do
        # Skip if already mailed (another job run got here first)
        next if order.mailed?

        order.update!(
          carrier: zen_order[:carrier],
          service: zen_order[:service],
          weight: zen_order[:weight],
          tracking_number: zen_order[:tracking_number],
          mailed_at: DateTime.parse(zen_order[:shipped_date]),
          postage_cost: zen_order[:shipping_handling],
          aasm_state: "mailed"
        )

        # Create postage ledger entry if the order is billable and postage is
        # known. `billable?` includes the BILLING_EPOCH floor, which keeps a
        # future backfill of billing_profile_id from sweeping the entire
        # pre-ledger backlog into a charge.
        # Guard: only create if no postage entry exists yet for this order
        if order.billable? &&
           zen_order[:shipping_handling].to_d.positive? &&
           !order.ledger_entries.postage.exists?
          order.ledger_entries.create!(
            billing_profile: order.billing_profile,
            category: :postage,
            amount_cents: (zen_order[:shipping_handling].to_d * 100).ceil,
          )
          orders_to_charge << order unless order.bulk_upload?
        end
      end

      # Send email outside the lock
      Warehouse::OrderMailer.with(order:).order_shipped.deliver_later
    end

    orders_to_charge.each do |order|
      order.charge_postage!
    rescue => e
      Sentry.capture_exception(e, extra: { order_id: order.id }) if defined?(Sentry)
    end
  end
end
