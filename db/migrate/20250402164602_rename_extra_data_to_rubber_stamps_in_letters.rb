class RenameExtraDataToRubberStampsInLetters < ActiveRecord::Migration[7.1]
  def change
    rename_column :letters, :extra_data, :rubber_stamps
  end
end
