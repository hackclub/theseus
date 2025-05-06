class AddIdempotencyKeyToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :idempotency_key, :string
    add_index :letters, :idempotency_key, unique: true
  end
end
