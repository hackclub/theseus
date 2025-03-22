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
    unit_costs = Zenventory.get_purchase_orders
                           .flat_map { |po| po[:items] }
                           .group_by { |item| item[:sku] }
                           .transform_values do |items|
                                    total_quantity = items.sum { |item| item[:quantity] }
                                    total_cost = items.sum { |item| item[:quantity] * item[:unitCost] }
                                    total_quantity.zero? ? 0 : total_cost.to_f / total_quantity
                                  end
    Rails.logger.info("okay!")

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
        average_po_cost: unit_cost&.round(4),
        in_stock: nilify(inv_item[:sellable]),
        zenventory_id: inv_item.dig(:item, :id)
      )
    end
  end

  def nilify(val)
    val&.zero? ? nil : val
  end
end
