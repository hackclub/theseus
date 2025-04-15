class RenameEventsOnRawJSONBatches < ActiveRecord::Migration[8.0]
  def change
    rename_column :usps_iv_mtr_raw_json_batches, :events, :payload
  end
end
