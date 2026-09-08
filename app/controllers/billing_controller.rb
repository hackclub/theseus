class BillingController < ApplicationController
  skip_after_action :verify_authorized

  def index
    @billing_profiles = current_user.billing_profiles.includes(:ledger_entries)
    @ledger_entries = LedgerEntry
      .where(billing_profile: @billing_profiles)
      .includes(:billing_profile, :ledgerable)
      .order(created_at: :desc)
      .page(params[:page]).per(50)

    render Views::Billing::Index.new(
      ledger_entries: @ledger_entries,
      billing_profiles: @billing_profiles,
    )
  end

  def show
    @ledger_entry = LedgerEntry
      .where(billing_profile: current_user.billing_profiles)
      .find(params[:id])

    render Views::Billing::Show.new(ledger_entry: @ledger_entry)
  end
end
