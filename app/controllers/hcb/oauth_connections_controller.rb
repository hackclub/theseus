class HCB::OauthConnectionsController < ApplicationController
  skip_after_action :verify_authorized, only: [:new, :callback]

  def new
    session[:hcb_oauth_state] = SecureRandom.urlsafe_base64(32)
    redirect_to hcb_oauth_authorize_url, allow_other_host: true
  end

  def callback
    expected_state = session.delete(:hcb_oauth_state)
    unless expected_state.present? && ActiveSupport::SecurityUtils.secure_compare(expected_state, params[:state].to_s)
      redirect_to root_path, alert: "HCB authorization failed (state mismatch)"
      return
    end

    code = params[:code]
    if code.blank?
      redirect_to root_path, alert: "HCB authorization failed"
      return
    end

    token = hcb_oauth_client.auth_code.get_token(
      code,
      redirect_uri: callback_hcb_oauth_connection_url,
    )

    connection = current_user.hcb_oauth_connection || current_user.build_hcb_oauth_connection
    if connection.persisted?
      connection.revalidate!(token)
    else
      connection.update!(
        access_token: token.token,
        refresh_token: token.refresh_token,
        expires_at: token.expires_at ? Time.at(token.expires_at) : nil,
      )
    end

    redirect_to hcb_payment_accounts_path, notice: "HCB account linked! Now create a payment account."
  end

  private

  def hcb_oauth_client
    @hcb_oauth_client ||= OAuth2::Client.new(
      ENV.fetch("HCB_CLIENT_ID"),
      ENV.fetch("HCB_CLIENT_SECRET"),
      site: "#{hcb_api_base}/api/v4/",
      authorize_url: "oauth/authorize",
      token_url: "oauth/token",
    )
  end

  def hcb_api_base
    ENV.fetch("HCB_API_BASE", "https://hcb.hackclub.com")
  end

  def hcb_oauth_authorize_url
    hcb_oauth_client.auth_code.authorize_url(
      redirect_uri: callback_hcb_oauth_connection_url,
      scope: "read write",
      state: session[:hcb_oauth_state],
    )
  end
end
