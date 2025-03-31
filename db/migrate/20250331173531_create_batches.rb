class CreateBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :batches do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :field_mapping
      t.timestamps
    end
  end
end
