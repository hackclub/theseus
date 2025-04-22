class CreateCommonTags < ActiveRecord::Migration[8.0]
  def change
    create_table :common_tags do |t|
      t.string :tag
      t.boolean :implies_ysws

      t.timestamps
    end
  end
end
