class AddApprovalFlowToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    # PO approval fields
    add_reference :warehouse_purchase_orders, :reviewed_by, foreign_key: { to_table: :users }
    add_column :warehouse_purchase_orders, :submitted_at, :datetime
    add_column :warehouse_purchase_orders, :reviewed_at, :datetime
    add_column :warehouse_purchase_orders, :rejection_reason, :text

    # Line items can reference a SKU request instead of (or in addition to) a real SKU
    change_column_null :warehouse_purchase_order_line_items, :sku_id, true
    add_reference :warehouse_purchase_order_line_items, :sku_request,
                  foreign_key: { to_table: :warehouse_sku_requests }
  end
end
