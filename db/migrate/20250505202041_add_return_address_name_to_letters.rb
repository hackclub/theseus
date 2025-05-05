class AddReturnAddressNameToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :return_address_name, :string
    add_column :batches, :letter_return_address_name, :string
  end
end
