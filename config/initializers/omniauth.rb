# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :hackclub,
    issuer: Rails.application.config.hack_club_auth.base_url,
    discovery: true,
    client_options: {
      identifier: Rails.application.config.hack_club_auth.client_id,
      secret: Rails.application.config.hack_club_auth.client_secret,
      redirect_uri: ENV.fetch("HACKCLUB_REDIRECT_URI", "http://localhost:3000/back_office/auth/hackclub/callback")
    },
    scope: %i[openid profile email slack_id]

  provider :openid_connect,
    name: :public_hackclub,
    path_prefix: "/auth",
    issuer: Rails.application.config.hack_club_auth.base_url,
    discovery: true,
    client_options: {
      identifier: ENV.fetch("PUBLIC_HACKCLUB_CLIENT_ID") { Rails.application.config.hack_club_auth.client_id },
      secret: ENV.fetch("PUBLIC_HACKCLUB_CLIENT_SECRET") { Rails.application.config.hack_club_auth.client_secret },
      redirect_uri: ENV.fetch("PUBLIC_HACKCLUB_REDIRECT_URI", "http://localhost:3000/auth/public_hackclub/callback")
    },
    scope: %i[openid profile email]
end

OmniAuth.config.path_prefix = "/back_office/auth"
OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
OmniAuth.config.allowed_request_methods = [ :post ]
