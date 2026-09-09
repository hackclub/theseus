# frozen_string_literal: true

# Every way billing asks for a human. Quiet by design: a transfer that will
# retry on its own is a log line, not an email. People hear about it the
# first time money is short, and when we've given up.
module Billing::Alert
  def self.insufficient_funds(transfer, first: true)
    unless first || transfer.gave_up?
      Rails.logger.warn("[billing] NSF again for #{transfer.idempotency_key} (attempt #{transfer.attempts}/#{HCB::Transfer::MAX_ATTEMPTS}); not re-alerting")
      return
    end

    BillingMailer.with(transfer: transfer, cc: transfer.billing_profile.user&.email).insufficient_funds.deliver_later
    Billing::SlackNotifyJob.notify(transfer, "nsf")
    Sentry.capture_message(
      "NSF: #{transfer.billing_profile.organization_name} can't pay #{Billing::Memo.money(transfer.amount_cents)} (attempt #{transfer.attempts}/#{HCB::Transfer::MAX_ATTEMPTS})",
      level: :error,
      tags: { money: true, nsf: true },
      extra: { transfer_id: transfer.id, billing_profile_id: transfer.billing_profile_id, attempts: transfer.attempts },
    ) if defined?(Sentry)
  end

  def self.transfer_failed(transfer)
    if transfer.retryable?
      Rails.logger.warn("[billing] transfer #{transfer.idempotency_key} failed (attempt #{transfer.attempts}/#{HCB::Transfer::MAX_ATTEMPTS}), retrying at #{transfer.next_attempt_at}: #{transfer.last_error}")
      return
    end

    BillingMailer.with(transfer: transfer).transfer_failed.deliver_later
    Billing::SlackNotifyJob.notify(transfer, "failed")
  end

  def self.transfer_unknown(transfer)
    BillingMailer.with(transfer: transfer).transfer_unknown.deliver_later
    Billing::SlackNotifyJob.notify(transfer, "unknown")
  end

  def self.reconcile_ambiguous(transfer)
    BillingMailer.with(transfer: transfer).reconcile_ambiguous.deliver_later
    Billing::SlackNotifyJob.notify(transfer, "ambiguous")
  end

  def self.ledger_mismatch(transfer, pending_cents)
    Sentry.capture_message(
      "billing ledger mismatch: transfer #{transfer.idempotency_key} is #{transfer.amount_cents}c but its pending entries sum to #{pending_cents}c; refused to send",
      level: :fatal, tags: { money: true, billing_mismatch: true }, extra: { transfer_id: transfer.id },
    ) if defined?(Sentry)
    BillingMailer.with(transfer: transfer).transfer_failed.deliver_later
    Billing::SlackNotifyJob.notify(transfer, "mismatch")
  end
end
