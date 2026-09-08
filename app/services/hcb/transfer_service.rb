class HCB::TransferService
  attr_reader :billing_profile, :amount_cents, :name, :memo, :errors

  def initialize(billing_profile:, amount_cents:, name:, memo: nil)
    @billing_profile = billing_profile
    @amount_cents = amount_cents
    @name = name
    @memo = memo
    @errors = []
  end

  def call
    return failure("No billing profile provided") unless billing_profile
    return failure("Amount must be positive") unless amount_cents.positive?

    transfer = billing_profile.create_disbursement!(
      amount_cents: amount_cents,
      name: name,
      memo: memo,
    )

    transfer
  rescue OAuth2::Error => e
    billing_profile.oauth_connection&.invalidate!
    failure("HCB connection expired — please relink your account")
  rescue HCB::OauthConnectionInvalidatedError
    failure("HCB connection has been invalidated — please relink your account")
  rescue HCBV4::APIError => e
    failure("HCB disbursement failed: #{e.message}")
  rescue => e
    failure("Transfer failed: #{e.message}")
  end

  private

  def failure(message)
    @errors << message
    false
  end
end
