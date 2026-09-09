# 20260908133544 is marked as run in dev but its columns never landed in the
# database or in schema.rb (dev was migrated, then the migration file was
# added, then the version was recorded without executing). Prod has run
# neither. This one is guarded so it is a no-op wherever the earlier one
# actually applied.
#
# Same shape as 20260908133544: no index (20260909160000 builds those
# concurrently) and NOT VALID foreign keys validated separately.
class EnsureBillingProfileOnWarehouseOrdersAndAPIKeys < ActiveRecord::Migration[8.0]
  def change
    add_reference :warehouse_orders, :billing_profile, null: true, index: false unless column_exists?(:warehouse_orders, :billing_profile_id)
    add_reference :api_keys, :billing_profile, null: true, index: false unless column_exists?(:api_keys, :billing_profile_id)

    unless foreign_key_exists?(:warehouse_orders, :hcb_payment_accounts, column: :billing_profile_id)
      add_foreign_key :warehouse_orders, :hcb_payment_accounts, column: :billing_profile_id, validate: false
    end

    unless foreign_key_exists?(:api_keys, :hcb_payment_accounts, column: :billing_profile_id)
      add_foreign_key :api_keys, :hcb_payment_accounts, column: :billing_profile_id, validate: false
    end

    reversible do |dir|
      dir.up do
        validate_foreign_key :warehouse_orders, :hcb_payment_accounts, column: :billing_profile_id
        validate_foreign_key :api_keys, :hcb_payment_accounts, column: :billing_profile_id
      end
    end
  end
end
