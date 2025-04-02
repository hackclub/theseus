class AddIMbIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :letters, :imb_serial_number
  end
end
