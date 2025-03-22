class AddNotifyOnDispatchToWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :warehouse_orders, :notify_on_dispatch, :boolean
  end
end
