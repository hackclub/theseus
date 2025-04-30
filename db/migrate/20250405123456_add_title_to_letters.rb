class AddTitleToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :user_facing_title, :string
  end
end 