class AddLetterReturnAddressToBatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :letter_return_address, null: true, foreign_key: { to_table: :return_addresses }
  end
end
