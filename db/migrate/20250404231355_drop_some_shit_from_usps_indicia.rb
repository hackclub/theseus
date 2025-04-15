class DropSomeShitFromUSPSIndicia < ActiveRecord::Migration[8.0]
  def change
    remove_column :usps_indicia, :postage_height
    remove_column :usps_indicia, :postage_length
    remove_column :usps_indicia, :postage_thickness
    remove_column :usps_indicia, :raw_usps_response
  end
end
