class AddTypeToBatches < ActiveRecord::Migration[7.1]
  def change
    add_column :batches, :type, :string, null: false, default: 'warehouse_orders'
    add_index :batches, :type
  end
end
