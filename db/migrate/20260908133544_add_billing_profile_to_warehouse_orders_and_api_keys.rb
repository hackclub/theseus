class AddBillingProfileToWarehouseOrdersAndAPIKeys < ActiveRecord::Migration[8.0]
  def change
    # nullable — existing orders don't have one, new ones will once the flag is on
    add_reference :warehouse_orders, :billing_profile, null: true,
      foreign_key: { to_table: :hcb_payment_accounts }

    add_reference :api_keys, :billing_profile, null: true,
      foreign_key: { to_table: :hcb_payment_accounts }
  end
end
