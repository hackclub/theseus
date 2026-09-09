class ReworkBillingLedger < ActiveRecord::Migration[8.0]
  def change
    # ── ledger_entries: signed, immutable, with reversal provenance ──
    add_reference :ledger_entries, :reverses, null: true, foreign_key: { to_table: :ledger_entries }
    add_check_constraint :ledger_entries, "amount_cents <> 0", name: "ledger_entries_amount_nonzero"
    add_index :ledger_entries, [:state, :hcb_transfer_id], name: "index_ledger_entries_unclaimed"

    # ── hcb_transfers: the unit of external-call safety ──
    rename_column :hcb_transfers, :hcb_transaction_id, :remote_id
    rename_column :hcb_transfers, :error_message, :last_error
    add_column :hcb_transfers, :direction, :integer, null: false, default: 0
    add_column :hcb_transfers, :hq_organization_id, :string, null: false  # hq-usps-ops or hq-warehouse-ops
    add_column :hcb_transfers, :idempotency_key, :string, null: false
    add_column :hcb_transfers, :name, :string
    add_column :hcb_transfers, :memo, :text
    add_column :hcb_transfers, :attempts, :integer, null: false, default: 0
    add_column :hcb_transfers, :last_attempted_at, :datetime
    add_column :hcb_transfers, :next_attempt_at, :datetime
    add_column :hcb_transfers, :metadata, :jsonb, default: {}
    add_index :hcb_transfers, :idempotency_key, unique: true
    add_index :hcb_transfers, [:state, :next_attempt_at]

    # ── batches: branch-only charge amount superseded by the ledger ──
    # (hcb_transfer_id on batches and usps_indicia predates the ledger and is
    #  kept read-only as a historical record; see Billing::Backfill.)
    remove_column :batches, :hcb_transfer_amount_cents, :integer if column_exists?(:batches, :hcb_transfer_amount_cents)
  end
end
