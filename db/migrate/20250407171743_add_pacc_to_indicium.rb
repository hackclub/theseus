class AddPaccToIndicium < ActiveRecord::Migration[8.0]
  def change
    add_reference :usps_indicia, :payment_account, null: true, foreign_key: { to_table: :usps_payment_accounts }
  end
end
