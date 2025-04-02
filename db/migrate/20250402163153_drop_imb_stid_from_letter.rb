class DropIMbStidFromLetter < ActiveRecord::Migration[8.0]
  def change
    remove_column :letters, :imb_stid
  end
end
