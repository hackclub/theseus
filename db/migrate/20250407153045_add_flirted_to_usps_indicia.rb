class AddFlirtedToUSPSIndicia < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_indicia, :flirted, :boolean
  end
end
