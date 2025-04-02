class AddWarehouseTemplateIdToBatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :warehouse_template, null: true, foreign_key: true
  end
end
