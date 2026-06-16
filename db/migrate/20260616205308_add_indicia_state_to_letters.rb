class AddIndiciaStateToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :indicia_state, :string
    add_column :letters, :indicia_error, :string
  end
end
