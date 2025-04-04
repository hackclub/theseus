class AddTemplateToWarehouseOrder < ActiveRecord::Migration[8.0]
  def change
    add_reference :warehouse_orders, :template, null: true, foreign_key: { to_table: :warehouse_templates }
  end
end
