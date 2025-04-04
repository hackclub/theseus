class AddTagsToStuff < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :tags, :citext, array: true, default: []
    add_column :warehouse_orders, :tags, :citext, array: true, default: []
    add_column :batches, :tags, :citext, array: true, default: []

    add_index :letters, :tags, using: "gin"
    add_index :warehouse_orders, :tags, using: "gin"
    add_index :batches, :tags, using: "gin"
  end
end
