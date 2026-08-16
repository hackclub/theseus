class Warehouse::UpdateInventoryLevelsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info("haiii!! it's ya girl cronjob coming to you with a hot new inventory update!")
    Rails.logger.info("taking zenventory...")
    inventory = Zenventory
                  .get_inventory
                  .index_by { |i| i.dig(:item, :sku) }

    Rails.logger.info("achievement get! fetched #{inventory.length} inventory items ^_^")

    Rails.logger.info("crunching unit cost numbers...")
    purchase_orders = Zenventory.get_purchase_orders
    all_po_items = purchase_orders.flat_map { |po| po[:items].map { |item| item.merge(po_id: po[:id]) } }
    grouped = all_po_items.group_by { |item| item[:sku] }

    zero_cost_items = []

    unit_costs = grouped.transform_values do |items|
      bad, good = items.partition { |item| item[:unitCost].nil? || item[:unitCost].zero? }

      if bad.any?
        zero_cost_items << {
          sku: items.first[:sku],
          count: bad.length,
          total_qty: bad.sum { |item| item[:quantity] },
          po_ids: bad.map { |i| i[:po_id] }.uniq,
        }
      end

      total_quantity = good.sum { |item| item[:quantity] }
      next nil if total_quantity.zero?

      total_cost = good.sum { |item| item[:quantity] * item[:unitCost] }
      (total_cost.to_f / total_quantity).round(4)
    end
    Rails.logger.info("okay!")

    if zero_cost_items.any?
      Rails.logger.warn("found #{zero_cost_items.length} SKU(s) with $0 PO items in zenventory! that's probably wrong!")
    end

    costless_skus = []
    zero_cost_sku_names = zero_cost_items.map { |i| i[:sku] }.to_set

    Warehouse::SKU.all.each do |i|
      sku = i.sku
      inv_item = inventory[sku]
      unit_cost = unit_costs[sku]
      unless inv_item
        Rails.logger.error("no item for #{sku} in warehouse inventory!")
        next
      end
      i.update(
        inbound: nilify(inv_item[:inbound]),
        average_po_cost: unit_cost,
        in_stock: nilify(inv_item[:sellable]),
        zenventory_id: inv_item.dig(:item, :id)
      )

      if i.enabled? && !i.declared_unit_cost.positive? && !zero_cost_sku_names.include?(sku)
        costless_skus << i
      end
    end

    local_skus = Warehouse::SKU.pluck(:sku).to_set
    new_sku_codes = []

    inventory.each do |sku_code, inv_item|
      next if local_skus.include?(sku_code)

      name = inv_item.dig(:item, :description) || sku_code
      sku = Warehouse::SKU.find_or_create_by!(sku: sku_code) do |s|
        s.name = name
        s.category = Warehouse::SKU.guess_category(name, sku_code)
        s.enabled = true
        s.zenventory_id = inv_item.dig(:item, :id)
        s.in_stock = nilify(inv_item[:sellable])
        s.inbound = nilify(inv_item[:inbound])
        s.average_po_cost = unit_costs[sku_code]
      end
      new_sku_codes << sku_code if sku.previously_new_record?
    rescue => e
      Rails.logger.error("failed to create SKU #{sku_code}: #{e.message}")
    end

    if new_sku_codes.any?
      Rails.logger.info("created #{new_sku_codes.length} new SKU(s) from zenventory: #{new_sku_codes.join(', ')}")
    end

    new_sku_codes.each do |sku_code|
      sku = Warehouse::SKU.find_by(sku: sku_code)
      next unless sku&.enabled? && !sku.declared_unit_cost.positive?
      costless_skus << sku unless zero_cost_sku_names.include?(sku_code)
    end

    uncategorized_skus = Warehouse::SKU.where(category: :unknown).to_a

    if costless_skus.any?
      Rails.logger.warn("#{costless_skus.length} enabled SKU(s) have no cost data at all: #{costless_skus.map(&:sku).join(', ')}")
      Warehouse::InventoryAlertMailer.cost_alert(costless_skus:).deliver_later
    end

    if uncategorized_skus.any?
      Warehouse::InventoryAlertMailer.category_alert(uncategorized_skus:).deliver_later
    end
  end

  def nilify(val)
    val&.zero? ? nil : val
  end
end
