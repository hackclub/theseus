class AddMailerIdToUSPSIVMTREvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :usps_iv_mtr_events, :mailer_id, null: false, foreign_key: { to_table: :usps_mailer_ids }, if_not_exists: true
  end
end
