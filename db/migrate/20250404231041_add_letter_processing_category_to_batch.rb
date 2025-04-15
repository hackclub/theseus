class AddLetterProcessingCategoryToBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :letter_processing_category, :integer
  end
end
