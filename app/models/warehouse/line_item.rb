# == Schema Information
#
# Table name: warehouse_line_items
#
#  id          :bigint           not null, primary key
#  quantity    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  order_id    :bigint
#  sku_id      :bigint           not null
#  template_id :bigint
#
# Indexes
#
#  index_warehouse_line_items_on_order_id     (order_id)
#  index_warehouse_line_items_on_sku_id       (sku_id)
#  index_warehouse_line_items_on_template_id  (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => warehouse_orders.id)
#  fk_rails_...  (sku_id => warehouse_skus.id)
#  fk_rails_...  (template_id => warehouse_templates.id)
#
class Warehouse::LineItem < ApplicationRecord
  belongs_to :order, class_name: "Warehouse::Order", optional: true
  belongs_to :sku, class_name: "Warehouse::SKU", optional: true
  belongs_to :template, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :sku, presence: true
end
