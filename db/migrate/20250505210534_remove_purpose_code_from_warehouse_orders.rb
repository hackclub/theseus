class RemovePurposeCodeFromWarehouseOrders < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :warehouse_orders, :warehouse_purpose_codes, column: :purpose_code_id
    remove_reference :warehouse_orders, :purpose_code
  end
end
