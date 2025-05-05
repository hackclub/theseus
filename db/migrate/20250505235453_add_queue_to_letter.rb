class AddQueueToLetter < ActiveRecord::Migration[8.0]
  def change
    add_reference :letters, :letter_queue, null: true, foreign_key: true
  end
end
