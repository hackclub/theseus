class AddApprovalFlowToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    # PO approval fields. The reference to users goes on NOT VALID and is
    # validated separately: users is large, and ADD CONSTRAINT ... VALIDATE
    # holds a lock on both tables for the length of the scan.
    add_reference :warehouse_purchase_orders, :reviewed_by
    add_column :warehouse_purchase_orders, :submitted_at, :datetime
    add_column :warehouse_purchase_orders, :reviewed_at, :datetime
    add_column :warehouse_purchase_orders, :rejection_reason, :text

    # Line items can reference a SKU request instead of (or in addition to) a real SKU
    change_column_null :warehouse_purchase_order_line_items, :sku_id, true
    add_reference :warehouse_purchase_order_line_items, :sku_request

    add_foreign_key :warehouse_purchase_orders, :users, column: :reviewed_by_id, validate: false
    add_foreign_key :warehouse_purchase_order_line_items, :warehouse_sku_requests, column: :sku_request_id, validate: false

    reversible do |dir|
      dir.up do
        validate_foreign_key :warehouse_purchase_orders, :users, column: :reviewed_by_id
        validate_foreign_key :warehouse_purchase_order_line_items, :warehouse_sku_requests, column: :sku_request_id
      end
    end
  end
end
