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
end
