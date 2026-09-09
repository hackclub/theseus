# Columns and FKs only. warehouse_orders is large, so the FKs go on NOT VALID
# and are validated under a weaker lock, and the billing_profile_id indexes
# are built concurrently in 20260909160000.
class AddBillingProfileToWarehouseOrdersAndAPIKeys < ActiveRecord::Migration[8.0]
  def change
    # nullable — existing orders don't have one, new ones will once the flag is on
    add_reference :warehouse_orders, :billing_profile, null: true, index: false
    add_reference :api_keys, :billing_profile, null: true, index: false

    add_foreign_key :warehouse_orders, :hcb_payment_accounts, column: :billing_profile_id, validate: false
    add_foreign_key :api_keys, :hcb_payment_accounts, column: :billing_profile_id, validate: false

    reversible do |dir|
      dir.up do
        validate_foreign_key :warehouse_orders, :hcb_payment_accounts, column: :billing_profile_id
        validate_foreign_key :api_keys, :hcb_payment_accounts, column: :billing_profile_id
      end
    end
  end
end
