class AddReturnAddressRefToLetters < ActiveRecord::Migration[8.0]
  def change
    add_reference :letters, :return_address, null: false, foreign_key: true
  end
end
