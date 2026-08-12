class AddWarehouseCzarToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_warehouse_czar, :boolean, default: false, null: false
  end
end
