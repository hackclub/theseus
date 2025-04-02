class AddBatchIdToLetters < ActiveRecord::Migration[8.0]
  def change
    add_reference :letters, :batch, null: true, foreign_key: true
  end
end
