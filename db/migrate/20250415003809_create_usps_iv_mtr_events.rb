class CreateUSPSIVMTREvents < ActiveRecord::Migration[8.0]
  def change
    create_table :usps_iv_mtr_events do |t|
      t.datetime :happened_at
      t.references :letter, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: { to_table: "usps_iv_mtr_raw_json_batches" }
      t.jsonb :payload
      t.string :opcode
      t.string :zip_code
      t.references :mailer_id, null: false, foreign_key: { to_table: :usps_mailer_ids }

      t.timestamps
    end

    add_index :usps_iv_mtr_events, [:mailer_id_id, :opcode]
    add_index :usps_iv_mtr_events, [:mailer_id_id, :happened_at]
  end
end
