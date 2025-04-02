module HasWarehouseLineItems
  extend ActiveSupport::Concern

  included do
    has_many :line_items, dependent: :destroy
    accepts_nested_attributes_for :line_items, reject_if: :all_blank, allow_destroy: true
    has_many :skus, through: :line_items
  end

  def labor_cost
    # $1.80 base * 20¢/SKU
    1.80 + (0.20 * skus.distinct.count)
  end

  def contents_actual_cost_to_hc
    line_items.joins(:sku).sum("warehouse_skus.actual_cost_to_hc * warehouse_line_items.quantity")
  end

  def contents_declared_unit_cost
    line_items.includes(:sku).sum do |line_item|
      (line_item.sku.declared_unit_cost || 0) * line_item.quantity
    end
  end
end
