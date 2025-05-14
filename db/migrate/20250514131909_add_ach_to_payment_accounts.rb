class AddAchToPaymentAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_payment_accounts, :ach, :boolean
  end
end
