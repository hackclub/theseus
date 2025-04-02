class AddBatchIdToWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :warehouse_orders, :batch, null: true, foreign_key: true
  end
end
