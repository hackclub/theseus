# deferred: move into db/migrate and run after the ui2-fr deploy has fully
# rolled out; old code reads source_tags
#
# 20260908130207_remove_source_tags already made the source_tag_id columns
# nullable, which is everything new code needs. This is the destructive
# remainder.
class DropSourceTags < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :warehouse_orders, :source_tags, if_exists: true
    remove_foreign_key :warehouse_templates, :source_tags, if_exists: true

    remove_index :warehouse_orders, :source_tag_id, if_exists: true
    remove_index :warehouse_templates, :source_tag_id, if_exists: true

    remove_column :warehouse_orders, :source_tag_id, :bigint
    remove_column :warehouse_templates, :source_tag_id, :bigint

    drop_table :source_tags do |t|
      t.string :slug
      t.string :name
      t.string :owner
      t.timestamps
    end
  end
end
