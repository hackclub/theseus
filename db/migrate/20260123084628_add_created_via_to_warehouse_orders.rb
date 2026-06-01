class AddCreatedViaToWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :warehouse_orders, :created_via, :integer, null: false, default: 0
    add_reference :warehouse_orders, :origin_batch, foreign_key: { to_table: :batches }, null: true

    add_index :warehouse_orders, :created_via

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE warehouse_orders
          SET created_via = CASE WHEN batch_id IS NOT NULL THEN 1 ELSE 0 END,
              origin_batch_id = batch_id
        SQL
      end
    end
  end
end
