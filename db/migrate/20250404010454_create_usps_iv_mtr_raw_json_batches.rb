class CreateUSPSIVMTRRawJSONBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :usps_iv_mtr_raw_json_batches do |t|
      t.jsonb :events
      t.boolean :processed
      t.string :message_group_id

      t.timestamps
    end
  end
end
