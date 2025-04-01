class AddWarehousePurposeCodeToBatch < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :warehouse_purpose_code, null: true, foreign_key: true
  end
end
