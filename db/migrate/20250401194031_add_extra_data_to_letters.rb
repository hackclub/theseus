class AddExtraDataToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :extra_data, :text
  end
end
