class AddUftToBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :warehouse_user_facing_title, :string
  end
end
