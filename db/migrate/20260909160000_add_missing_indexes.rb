class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :warehouse_orders, :aasm_state, if_not_exists: true
    add_index :letters, :aasm_state, if_not_exists: true
    add_index :batches, :aasm_state, if_not_exists: true
    add_index :hcb_payment_accounts, :organization_id, if_not_exists: true
    add_index :hcb_transfers, :hq_organization_id, if_not_exists: true
    add_index :warehouse_orders, :zenventory_id, if_not_exists: true
  end
end
