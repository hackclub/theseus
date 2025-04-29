class AddCostsToWarehouseOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_orders, :labor_cost, :decimal, precision: 10, scale: 2
    add_column :warehouse_orders, :contents_cost, :decimal, precision: 10, scale: 2
  end
end
