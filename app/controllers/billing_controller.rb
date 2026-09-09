class BillingController < ApplicationController
  def index
    authorize LedgerEntry
    @billing_profiles = policy_scope(BillingProfile).includes(:ledger_entries)
    @ledger_entries = policy_scope(LedgerEntry)
      .includes(:billing_profile, :ledgerable, :hcb_transfer)
      .order(created_at: :desc)
      .page(params[:page]).per(50)

    render Views::Billing::Index.new(
      ledger_entries: @ledger_entries,
      billing_profiles: @billing_profiles,
    )
  end

  def show
    @ledger_entry = policy_scope(LedgerEntry).find(params[:id])
    authorize @ledger_entry

    render Views::Billing::Show.new(ledger_entry: @ledger_entry)
  end

  # Admin: re-execute a failed transfer, or force a stuck unknown one back
  # through (only do that after checking HCB by hand).
  def retry_transfer
    authorize LedgerEntry, :retry_transfer?
    transfer = HCB::Transfer.find(params[:transfer_id])

    # HCB v4 has no idempotency keys. An unknown transfer may already have been
    # processed, so re-sending it is a fresh movement of money — never do that
    # off a stray link or a double-submit; it takes an explicit force=1.
    if transfer.unknown? && params[:force] != "1"
      return redirect_back fallback_location: billing_index_path,
        alert: "Transfer #{transfer.idempotency_key} is UNKNOWN and may already have landed on HCB. Retrying it can charge twice, so it needs an explicit force."
    end

    transfer.retry!
    Billing.execute!(transfer)
    redirect_back fallback_location: billing_index_path, notice: "Transfer #{transfer.idempotency_key} is now #{transfer.state}#{transfer.last_error ? ": #{transfer.last_error}" : ""}"
  rescue => e
    redirect_back fallback_location: billing_index_path, alert: e.message
  end
end
