class DropPaccIdFromUSPSIndicia < ActiveRecord::Migration[8.0]
  def change
    remove_column :usps_indicia, :payment_account_id
  end
end
