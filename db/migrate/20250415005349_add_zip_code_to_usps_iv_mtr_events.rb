class AddZipCodeToUSPSIVMTREvents < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_iv_mtr_events, :zip_code, :string
  end
end
