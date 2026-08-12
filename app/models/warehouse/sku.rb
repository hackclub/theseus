# == Schema Information
#
# Table name: warehouse_skus
#
#  id                          :bigint           not null, primary key
#  actual_cost_to_hc           :decimal(, )
#  ai_enabled                  :boolean
#  average_po_cost             :decimal(, )
#  category                    :integer
#  country_of_origin           :string
#  customs_description         :text
#  declared_unit_cost_override :decimal(, )
#  description                 :text
#  enabled                     :boolean
#  hs_code                     :string
#  in_stock                    :integer
#  inbound                     :integer
#  name                        :string
#  sku                         :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  zenventory_id               :string
#
# Indexes
#
#  index_warehouse_skus_on_sku  (sku) UNIQUE
#
class Warehouse::SKU < ApplicationRecord
  has_paper_trail

  scope :in_inventory, -> { where.not(in_stock: nil, inbound: nil) }
  scope :backordered, -> { where("in_stock < 0") }

  def declared_unit_cost
    [declared_unit_cost_override, average_po_cost].find { |c| c&.positive? } || 0.0
  end

  enum :category, {
    sticker: 0,
    poster: 1,
    card: 2,
    flyer: 3,
    other_printed_material: 4,
    hardware: 5,
    book: 6,
    swag: 7,
    grant: 8,
    prize: 9,
    unknown: 10,
  }

  def self.guess_category(name, sku_code = nil)
    parts = sku_code.to_s.split("/")
    prefix = parts.first&.downcase

    case prefix
    when "sti" then return :sticker
    when "har", "kit" then return :hardware
    when "swa", "shirt" then return :swag
    when "boo" then return :book
    when "gra" then return :grant
    when "prz" then return :prize
    when "pri"
      return :poster if parts.any? { |p| p.match?(/^(11x|x11)/i) }
      return :card if parts.any? { |p| p.match?(/^(4x6|x4)$/i) }
      return :flyer if parts.any? { |p| p.match?(/^8\.?5$/i) }
      return :book if parts.any? { |p| p.downcase == "bok" }
      name_lower = name.to_s.downcase
      return :poster if name_lower.match?(/poster/)
      return :card if name_lower.match?(/\bcard\b|postcard/)
      return :flyer if name_lower.match?(/\bflyer\b/)
      return :other_printed_material
    end

    return :sticker if parts.any? { |p| p.downcase == "sti" }

    text = name.to_s.downcase
    return :sticker if text.match?(/sticker/)
    return :poster if text.match?(/poster/)
    return :card if text.match?(/\bcard\b|postcard/)
    return :flyer if text.match?(/\bflyer\b/)
    return :book if text.match?(/\bbook\b|zine|magazine/)
    return :hardware if text.match?(/\bboard\b|pcb|arduino|raspberry|pico/)
    return :swag if text.match?(/shirt|hoodie|\bhat\b|\bpin\b|\bsock\b|\bbag\b|plush|lanyard/)
    return :grant if text.match?(/\bgrant\b/)
    return :prize if text.match?(/\bprize\b/)
    :unknown
  end

  include HasTableSync
  include HasZenventoryUrl

  has_table_sync ENV["AIRTABLE_THESEUS_BASE"],
                 ENV["AIRTABLE_SKUS_TABLE"],
                 {
                   sku: :sku,
                   name: :name,
                   category: ->(_) { category.to_s.humanize },
                   enabled: :enabled,
                   declared_unit_cost: :declared_unit_cost,
                   actual_cost_to_hc: :actual_cost_to_hc,
                   in_stock: :in_stock,
                   inbound: :inbound,
                 }

  has_zenventory_url "https://app.zenventory.com/admin/item-details/%s/basic", :zenventory_id

  def sync_to_zenventory!
    params = {
      sku: sku,
      description: name,
      category: category&.to_s&.humanize,
      active: enabled || false,
      unitCost: declared_unit_cost,
      userField1: country_of_origin,
      userField2: hs_code,
    }.compact

    if zenventory_id.present?
      Zenventory.update_item(zenventory_id, params)
    else
      response = Zenventory.create_item(params)
      update!(zenventory_id: response[:id].to_s)
    end
  end
end
