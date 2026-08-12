class RenameRejectedToReturned < ActiveRecord::Migration[8.0]
  def change
    rename_column :warehouse_sku_requests, :rejection_reason, :reviewer_notes
    rename_column :warehouse_purchase_orders, :rejection_reason, :reviewer_notes

    # Update any existing state values
    reversible do |dir|
      dir.up do
        execute "UPDATE warehouse_sku_requests SET aasm_state = 'returned' WHERE aasm_state = 'rejected'"
        execute "UPDATE warehouse_purchase_orders SET status = 'returned' WHERE status = 'rejected'"
      end
      dir.down do
        execute "UPDATE warehouse_sku_requests SET aasm_state = 'rejected' WHERE aasm_state = 'returned'"
        execute "UPDATE warehouse_purchase_orders SET status = 'rejected' WHERE status = 'returned'"
      end
    end
  end
end
