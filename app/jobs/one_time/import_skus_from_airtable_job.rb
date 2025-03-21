class OneTime::ImportSKUsFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(*args)
    at_skus = Airtable::WarehouseSKU.where("NOT({Item Type}='Kit')")

    at_skus.each do |at_sku|
      Warehouse::SKU.find_or_create_by!(sku: at_sku.sku) do |sku|
        sku.name = at_sku.name
        sku.category = case at_sku.item_type
        when "Printed Material"
                         name = at_sku.name.downcase
                         if name.include? "card"
                           :card
                         elsif name.include? "poster"
                           :poster
                         elsif name.include? "flyer"
                           :flyer
                         else
                           :other_printed_material
                         end
        when "Grant"
                         :grant
        when "Sticker"
                         :sticker
        when "Hardware"
                         :hardware
        when "Swag"
                         :swag
        when "Book"
                         :book
        when "Prize"
                         :prize
        end
        sku.in_stock = at_sku.in_stock
        sku.average_po_cost = at_sku.unit_cost
        sku.actual_cost_to_hc = at_sku.unit_cost
      end
    end
  end
end
