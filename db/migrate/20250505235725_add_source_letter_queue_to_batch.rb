class AddSourceLetterQueueToBatch < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :letter_queue, null: true, foreign_key: true
  end
end
