class AddIdempotencyKeyToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :idempotency_key, :string, if_not_exists: true
    add_index :letters, :idempotency_key, unique: true, if_not_exists: true
  end
end
