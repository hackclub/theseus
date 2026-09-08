class CreateLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_entries do |t|
      t.references :billing_profile, null: false, foreign_key: { to_table: :hcb_payment_accounts }
      t.references :ledgerable, polymorphic: true, null: false
      t.integer :category, null: false
      t.integer :amount_cents, null: false
      t.integer :state, null: false, default: 0
      t.datetime :settled_at
      t.string :hcb_transfer_id
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :ledger_entries, :state
    add_index :ledger_entries, :category
    add_index :ledger_entries, :hcb_transfer_id
    add_index :ledger_entries, [:billing_profile_id, :state]
  end
end
