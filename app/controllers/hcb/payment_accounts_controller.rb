class HCB::PaymentAccountsController < ApplicationController
  before_action :require_hcb_connection, except: [:index]
  before_action :set_payment_account, only: [:show]

  rescue_from HCBV4::APIError do |e|
    event_id = Sentry.capture_exception(e, extra: { user_id: current_user.id })&.event_id
    redirect_to hcb_payment_accounts_path, alert: "Failed to load HCB organizations: #{e.message} (#{event_id})"
  end

  rescue_from OAuth2::Error do |e|
    Sentry.capture_exception(e, extra: { user_id: current_user.id, response_body: e.response&.body })
    current_user.hcb_oauth_connection&.invalidate!
    redirect_to hcb_payment_accounts_path
  end

  rescue_from HCB::OauthConnectionInvalidatedError do
    redirect_to hcb_payment_accounts_path
  end

  def index
    authorize BillingProfile
    @payment_accounts = policy_scope(BillingProfile)
  end

  def new
    @payment_account = current_user.billing_profiles.build
    authorize @payment_account
    @organizations = available_organizations
  end

  def create
    @payment_account = current_user.billing_profiles.build(
      oauth_connection: current_user.hcb_oauth_connection,
    )
    authorize @payment_account

    org = find_organization(params[:organization_id])
    if org.nil?
      redirect_to new_hcb_payment_account_path, alert: "Organization not found"
      return
    end

    @payment_account.assign_attributes(
      organization_id: org.id,
      organization_name: org.name,
    )

    if @payment_account.save
      redirect_to hcb_payment_accounts_path, notice: "Billing profile created for #{org.name}"
    else
      @organizations = available_organizations
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @payment_account
  end

  private

  def require_hcb_connection
    unless current_user.hcb_connected?
      redirect_to new_hcb_oauth_connection_path, alert: "Please link your HCB account first"
    end
  end

  def set_payment_account
    @payment_account = policy_scope(BillingProfile).find(params[:id])
  end

  def available_organizations
    current_user.hcb_oauth_connection.organizations.reject do |org|
      BillingProfile::BLOCKED_ORGANIZATION_IDS.include?(org.id)
    end
  end

  def find_organization(org_id)
    available_organizations.find { |o| o.id == org_id }
  end
end
