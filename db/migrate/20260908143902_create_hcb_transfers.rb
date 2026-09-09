class CreateHCBTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :hcb_transfers do |t|
      t.references :billing_profile, null: false, foreign_key: { to_table: :hcb_payment_accounts }
      t.integer :amount_cents, null: false
      t.string :hcb_transaction_id
      t.integer :state, null: false, default: 0
      t.string :error_message
      t.timestamps
    end

    add_index :hcb_transfers, :state
    add_index :hcb_transfers, :hcb_transaction_id

    # Replace the string hcb_transfer_id column with a proper FK to hcb_transfers.
    # The column only ever existed in dev (an earlier edit of the create_ledger_entries
    # migration); on a fresh database there is nothing to drop.
    if column_exists?(:ledger_entries, :hcb_transfer_id)
      remove_index :ledger_entries, :hcb_transfer_id, if_exists: true
      remove_column :ledger_entries, :hcb_transfer_id, :string
    end
    add_reference :ledger_entries, :hcb_transfer, null: true, foreign_key: true
  end
end
