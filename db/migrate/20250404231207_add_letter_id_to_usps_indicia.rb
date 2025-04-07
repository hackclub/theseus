class AddLetterIdToUSPSIndicia < ActiveRecord::Migration[8.0]
  def change
    add_reference :usps_indicia, :letter, null: true, foreign_key: true
  end
end
