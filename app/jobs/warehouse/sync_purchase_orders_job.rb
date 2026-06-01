# frozen_string_literal: true

class Warehouse::SyncPurchaseOrdersJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("syncing purchase orders from zenventory...")

    zenv_pos = Zenventory.get_purchase_orders
    Rails.logger.info("fetched #{zenv_pos.length} POs from zenventory")
    zenv_pos.each do |zenv_po|
      sync_purchase_order(zenv_po)
    rescue => e
      Rails.logger.error("failed to sync PO #{zenv_po[:id]}: #{e.message}")
    end

    Rails.logger.info("done syncing purchase orders!")
  end

  private

  def sync_purchase_order(zenv_po)
    po = Warehouse::PurchaseOrder.find_by(zenventory_id: zenv_po[:id])

    if po
      po.sync_from_zenventory!
    else
      create_purchase_order_from_zenventory(zenv_po)
    end
  end

  def create_purchase_order_from_zenventory(zenv_po)
    user = User.find_by(email: "theseus@hackclub.com") || User.first

    po = Warehouse::PurchaseOrder.new(
      zenventory_id: zenv_po[:id],
      order_number: zenv_po[:orderNumber],
      supplier_name: zenv_po.dig(:supplier, :name) || "Unknown",
      supplier_id: zenv_po.dig(:supplier, :id),
      notes: zenv_po[:notes],
      required_by_date: zenv_po[:requiredByDate].present? ? Date.parse(zenv_po[:requiredByDate]) : nil,
      status: normalize_status(zenv_po),
      user: user
    )

    zenv_po[:items]&.each do |item|
      sku = Warehouse::SKU.find_by(sku: item[:sku])
      next unless sku

      po.line_items.build(
        sku: sku,
        quantity: item[:quantity],
        unit_cost: item[:unitCost]
      )
    end

    if po.line_items.any?
      po.save!
      Rails.logger.info("created PO #{po.order_number} from zenventory")
    else
      Rails.logger.warn("skipping PO #{zenv_po[:orderNumber]} - no matching SKUs")
    end
  end

  def normalize_status(zenv_po)
    if zenv_po[:deleted]
      "deleted"
    elsif zenv_po[:completed]
      "completed"
    elsif zenv_po[:draft]
      "draft"
    else
      "open"
    end
  end
end
