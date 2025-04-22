class MakeLetterIdNullableInIVMTREvents < ActiveRecord::Migration[8.0]
  def change
    change_column_null :usps_iv_mtr_events, :letter_id, true, if_exists: true
    remove_foreign_key :usps_iv_mtr_events, :letters, if_exists: true 
    add_foreign_key :usps_iv_mtr_events, :letters, on_delete: :nullify
  end
end 