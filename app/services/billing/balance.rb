# frozen_string_literal: true

# Cached HCB balance for a profile; nil when HCB can't be reached.
#
# The OAuth refresh runs *outside* the timeout: HCB rotates the refresh
# token on use, so interrupting that write would strand the connection.
# Only the balance GET itself is allowed to be cut short. Failures are
# remembered briefly so a slow HCB costs one wait per profile, not one
# per render.
module Billing::Balance
  CACHE_TTL = 1.minute
  FAILURE_TTL = 15.seconds
  TIMEOUT = 4
  UNAVAILABLE = :unavailable

  def self.cents_for(profile)
    return nil if profile.nil? || Billing.mock?

    cached = Rails.cache.read(key(profile))
    return (cached == UNAVAILABLE ? nil : cached) unless cached.nil?

    cents = fetch(profile)
    Rails.cache.write(key(profile), cents || UNAVAILABLE, expires_in: cents ? CACHE_TTL : FAILURE_TTL)
    cents
  end

  def self.forget!(profile)
    Rails.cache.delete(key(profile))
  end

  def self.key(profile) = [ "billing/balance", profile.id ]

  def self.fetch(profile)
    profile.client.send(:refresh_token_if_needed!)  # hcbv4 marks it private; it is exactly the step we must not interrupt
    Timeout.timeout(TIMEOUT) { profile.organization.balance_cents&.to_i }
  rescue => e
    Rails.logger.warn("[Billing::Balance] could not fetch balance for profile #{profile.id}: #{e.class}: #{e.message}")
    nil
  end
  private_class_method :fetch
end
