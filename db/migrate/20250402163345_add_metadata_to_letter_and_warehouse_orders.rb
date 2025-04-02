class AddMetadataToLetterAndWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :warehouse_orders, :metadata, :jsonb
    add_column :letters, :metadata, :jsonb
  end
end
