# frozen_string_literal: true

# == Schema Information
#
# Table name: warehouse_purchase_order_line_items
#
#  id                :bigint           not null, primary key
#  quantity          :integer          not null
#  unit_cost         :decimal(10, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  purchase_order_id :bigint           not null
#  sku_id            :bigint
#  sku_request_id    :bigint
#
# Indexes
#
#  index_warehouse_purchase_order_line_items_on_purchase_order_id  (purchase_order_id)
#  index_warehouse_purchase_order_line_items_on_sku_id             (sku_id)
#  index_warehouse_purchase_order_line_items_on_sku_request_id     (sku_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (purchase_order_id => warehouse_purchase_orders.id)
#  fk_rails_...  (sku_id => warehouse_skus.id)
#  fk_rails_...  (sku_request_id => warehouse_sku_requests.id)
#
class Warehouse::PurchaseOrderLineItem < ApplicationRecord
  belongs_to :purchase_order, class_name: "Warehouse::PurchaseOrder", inverse_of: :line_items
  belongs_to :sku, class_name: "Warehouse::SKU", optional: true
  belongs_to :sku_request, class_name: "Warehouse::SKURequest", optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :must_have_sku_or_request

  def resolved?
    sku_id.present?
  end

  def display_name
    if sku
      sku.name
    elsif sku_request
      "#{sku_request.name} (pending)"
    else
      "Unknown"
    end
  end

  private

  def must_have_sku_or_request
    unless sku_id.present? || sku_request_id.present?
      errors.add(:base, "must reference a SKU or SKU request")
    end
  end
end
