class MakePurposeCodeOptionalInWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    change_column_null :warehouse_orders, :purpose_code_id, true
  end
end 