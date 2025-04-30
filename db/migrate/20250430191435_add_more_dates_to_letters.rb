class AddMoreDatesToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :printed_at, :datetime
    add_column :letters, :mailed_at, :datetime
    add_column :letters, :received_at, :datetime
  end
end
