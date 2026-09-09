# frozen_string_literal: true

# Sends one HCB::Transfer to HCB and resolves it. The whole point of this
# class is the error classification:
#
#   definite  HCB told us no, or the request never left. Nothing was
#             created on HCB's side. Safe to retry (same key).
#   unknown   The request may have been processed. We have no proof either
#             way. NOT retried; Billing::Reconciler resolves it.
#
# When in doubt, unknown. A stuck transfer costs an email and a human
# minute. A double charge costs real money and trust.
class Billing::Executor
  # The request never reached HCB, or HCB rejected it outright.
  DEFINITE = [
    HCBV4::BadRequestError,
    HCBV4::UnauthorizedError,
    HCBV4::ForbiddenError,
    HCBV4::NotFoundError,
    HCBV4::UnprocessableEntityError,
    HCBV4::RateLimitError,
    HCBV4::InvalidOperationError,
    HCBV4::InvalidUserError,
    HCBV4::AuthenticationError,
    HCB::OauthConnectionInvalidatedError,
    OAuth2::Error,               # token refresh happens before the request is sent
    Faraday::ConnectionFailed,   # could not connect: nothing was sent
    Faraday::SSLError,
  ].freeze

  # These need a human (relink, fix config) rather than a backoff.
  NOT_RETRYABLE = [
    HCBV4::UnauthorizedError,
    HCBV4::ForbiddenError,
    HCBV4::NotFoundError,
    HCBV4::AuthenticationError,
    HCB::OauthConnectionInvalidatedError,
    OAuth2::Error,
  ].freeze

  INSUFFICIENT = /enough money|insufficient/i

  attr_reader :transfer

  def initialize(transfer)
    @transfer = transfer
  end

  def call
    return transfer unless transfer.pending? || transfer.retryable?
    return transfer if transfer.pending? && transfer.last_attempted_at.present?  # in flight or stale; reconciler's job

    transfer.begin_attempt!

    if Billing.mock?
      transfer.complete!("mock_#{SecureRandom.hex(6)}")
      return transfer
    end

    result = send_request
    return transfer unless result  # classified and recorded inside send_request

    record!(result)
    write_memo(result)
    transfer
  end

  private

  # Only the HTTP call is inside the classifying rescue. Anything that goes
  # wrong *after* HCB answered is a bug on our side and must not be
  # mistaken for "HCB may not have processed it".
  def send_request
    if transfer.debit?
      transfer.billing_profile.create_disbursement!(
        to_organization_id: transfer.hq_organization_id,
        amount_cents: transfer.amount_cents,
        name: transfer.tagged_name,
      )
    else
      BillingProfile.refund_to_organization!(
        from_organization_id: transfer.hq_organization_id,
        organization_id: transfer.billing_profile.organization_id,
        amount_cents: transfer.amount_cents,
        name: transfer.tagged_name,
      )
    end
  rescue *DEFINITE => e
    reject(e)
    nil
  rescue => e
    # Faraday::TimeoutError, HCBV4::ServerError, HCBV4::APIError, anything we
    # didn't anticipate: the request may have gone through.
    transfer.mark_unknown!(describe(e))
    Sentry.capture_exception(e, level: :error, tags: { money: true, billing_unknown: true }, extra: { transfer_id: transfer.id }) if defined?(Sentry)
    BillingMailer.with(transfer: transfer).transfer_unknown.deliver_later
    nil
  end

  # remote_id first, on its own; then the entries. If the second step raises
  # the transfer is still completed and the sweep repairs the entries.
  def record!(result)
    transfer.complete!(result.id)
  rescue => e
    Sentry.capture_exception(e, level: :fatal, tags: { money: true, billing_record_failed: true },
      extra: { transfer_id: transfer.id, remote_id: result.id }) if defined?(Sentry)
    transfer.update_columns(state: HCB::Transfer.states[:completed], remote_id: result.id, last_error: "recorded remote id; settling entries failed: #{e.message}".truncate(255)) unless transfer.reload.completed?
    raise
  end

  # Best effort. A memo that fails to write must never look like a charge
  # that failed to happen.
  def write_memo(result)
    transaction_id = result.try(:transaction_id)
    return transfer.update!(metadata: transfer.metadata.merge("memo_pending" => true)) if transaction_id.blank?

    memo = "#{transfer.memo.presence || transfer.name} [#{transfer.idempotency_key}]".truncate(500)
    if transfer.debit?
      transfer.billing_profile.set_transaction_memo!(transaction_id, memo)
    else
      BillingProfile.set_hq_transaction_memo!(transfer.hq_organization_id, transaction_id, memo)
    end
    transfer.update!(metadata: transfer.metadata.merge("remote_transaction_id" => transaction_id).except("memo_pending"))
  rescue => e
    transfer.update!(metadata: transfer.metadata.merge("memo_pending" => true, "remote_transaction_id" => transaction_id, "memo_error" => e.message.truncate(200)))
    Rails.logger.warn("[billing] memo write failed for transfer #{transfer.id}: #{e.message}")
  end

  def reject(error)
    message = describe(error)
    transfer.billing_profile.oauth_connection&.invalidate! if error.is_a?(OAuth2::Error) && transfer.debit?

    retryable = NOT_RETRYABLE.none? { |k| error.is_a?(k) }
    transfer.fail!(message, retryable: retryable)

    if message.match?(INSUFFICIENT)
      # Once, on the first attempt; the backoff will keep trying quietly.
      BillingMailer.with(transfer: transfer).insufficient_funds.deliver_later if transfer.attempts == 1
    elsif !retryable || transfer.gave_up?
      BillingMailer.with(transfer: transfer).transfer_failed.deliver_later
    end
  end

  def describe(error)
    case error
    when HCB::OauthConnectionInvalidatedError, OAuth2::Error
      "HCB connection expired — please relink your account"
    when HCBV4::APIError
      "HCB #{error.status}: #{error.message}"
    else
      "#{error.class}: #{error.message}"
    end
  end
end
