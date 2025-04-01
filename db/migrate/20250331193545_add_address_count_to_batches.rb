class AddAddressCountToBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :address_count, :integer
  end
end
