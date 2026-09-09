# This migration creates the `versions` table, the only schema PT requires.
# All other migrations PT provides are optional.
class CreateVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :versions do |t|
      t.string   :whodunnit
      t.datetime :created_at
      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false
      t.string   :event,     null: false
      t.jsonb    :object
      t.inet     :ip
      t.bigint   :api_key_id
    end
    add_index :versions, %i[item_type item_id]
    add_index :versions, :created_at
  end
end
