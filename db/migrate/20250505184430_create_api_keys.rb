class CreateAPIKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :revoked_at
      t.boolean :pii
      t.text :token_ciphertext
      t.string :token_bidx, index: {unique: true}
      t.string :name
      t.timestamps
    end
  end
end
