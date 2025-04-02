class AddLetterAttributesToBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :letter_height, :decimal
    add_column :batches, :letter_width, :decimal
    add_column :batches, :letter_weight, :decimal
  end
end
