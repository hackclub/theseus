class AddFeesToUSPSIndicia < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_indicia, :fees, :decimal
  end
end
