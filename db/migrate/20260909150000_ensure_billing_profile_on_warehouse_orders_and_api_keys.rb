# 20260908133544 is marked as run in dev but its columns never landed in the
# database or in schema.rb (dev was migrated, then the migration file was
# added, then the version was recorded without executing). Prod has run
# neither. This one is guarded so it is a no-op wherever the earlier one
# actually applied.
class EnsureBillingProfileOnWarehouseOrdersAndAPIKeys < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:warehouse_orders, :billing_profile_id)
      add_reference :warehouse_orders, :billing_profile, null: true, foreign_key: { to_table: :hcb_payment_accounts }
    end
    unless column_exists?(:api_keys, :billing_profile_id)
      add_reference :api_keys, :billing_profile, null: true, foreign_key: { to_table: :hcb_payment_accounts }
    end
  end
end
