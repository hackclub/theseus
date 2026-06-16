class AddHCBChargeAmountToBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :hcb_transfer_amount_cents, :integer
  end
end
