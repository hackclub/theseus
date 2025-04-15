class AddOpcodeToUSPSIVMTREvents < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_iv_mtr_events, :opcode, :string
  end
end
