class AddRawJsonResponseToUSPSIndicia < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_indicia, :raw_json_response, :jsonb
  end
end
