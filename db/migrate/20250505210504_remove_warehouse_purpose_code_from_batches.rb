class RemoveWarehousePurposeCodeFromBatches < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :batches, :warehouse_purpose_codes
    remove_reference :batches, :warehouse_purpose_code
  end
end
