class RemoveSourceTags < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :warehouse_orders, :source_tags
    remove_foreign_key :warehouse_templates, :source_tags

    remove_index :warehouse_orders, :source_tag_id
    remove_index :warehouse_templates, :source_tag_id

    remove_column :warehouse_orders, :source_tag_id, :bigint, null: false
    remove_column :warehouse_templates, :source_tag_id, :bigint, null: false

    drop_table :source_tags do |t|
      t.string :slug
      t.string :name
      t.string :owner
      t.timestamps
    end
  end
end
