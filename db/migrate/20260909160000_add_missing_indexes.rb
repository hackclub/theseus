# All of these are on tables that are already large in production, so every
# index is built concurrently. That requires the migration to run outside a
# transaction; each statement is independently idempotent (if_not_exists), so
# a partial run is safe to retry. Note that an interrupted concurrent build
# leaves an INVALID index behind — drop it before re-running.
class AddMissingIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :warehouse_orders, :aasm_state, algorithm: :concurrently, if_not_exists: true
    add_index :letters, :aasm_state, algorithm: :concurrently, if_not_exists: true
    add_index :batches, :aasm_state, algorithm: :concurrently, if_not_exists: true
    add_index :hcb_payment_accounts, :organization_id, algorithm: :concurrently, if_not_exists: true
    add_index :hcb_transfers, :hq_organization_id, algorithm: :concurrently, if_not_exists: true
    add_index :warehouse_orders, :zenventory_id, algorithm: :concurrently, if_not_exists: true

    # Deferred here from 20260908133544 / 20260909150000, which add the columns.
    add_index :warehouse_orders, :billing_profile_id, algorithm: :concurrently, if_not_exists: true
    add_index :api_keys, :billing_profile_id, algorithm: :concurrently, if_not_exists: true
  end
end
