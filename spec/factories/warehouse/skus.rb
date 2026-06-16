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
FactoryBot.define do
  factory :warehouse_sku, class: "Warehouse::SKU" do
    sequence(:sku) { |n| "Test/Sku/#{n}" }
    sequence(:name) { |n| "Test SKU #{n}" }
    enabled { true }
    category { :hardware }
  end
end
