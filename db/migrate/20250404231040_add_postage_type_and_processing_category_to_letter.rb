class AddPostageTypeAndProcessingCategoryToLetter < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :postage_type, :integer
  end
end
