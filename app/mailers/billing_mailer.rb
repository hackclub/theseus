# Like every GenericTextMailer, the SMTP envelope goes to the Loops relay;
# the real recipient is the `email` field in the JSON body (@recipient).
class BillingMailer < GenericTextMailer
  DEFAULT_TO = "nora@hackclub.com"
  LOOPS_RELAY = "dinobox@hackclub.com"

  def self.ops_email = ENV.fetch("BILLING_ALERT_EMAIL", DEFAULT_TO)

  before_action do
    @transfer = params[:transfer]
    @profile = @transfer.billing_profile
    @recipient = params[:recipient].presence || self.class.ops_email
    @cc = params[:cc].presence  # the Loops template CCs this
    @attempt = "attempt #{@transfer.attempts}/#{HCB::Transfer::MAX_ATTEMPTS}"
  end

  def transfer_failed
    @subject = if @transfer.last_error.to_s.start_with?("ledger mismatch")
      "[theseus] [billing] 💀 refused to send #{@transfer.idempotency_key}: ledger mismatch"
    elsif @transfer.gave_up?
      "[theseus] [billing] #{@profile.organization_name} transfer gave up after #{@transfer.attempts} attempts"
    else
      "[theseus] [billing] #{@profile.organization_name} transfer failed (#{@attempt})"
    end
    mail to: LOOPS_RELAY
  end

  def insufficient_funds
    @subject = "[theseus] Insufficient funds: #{@profile.organization_name} could not cover #{Billing::Memo.money(@transfer.amount_cents)}"
    mail to: LOOPS_RELAY
  end

  def transfer_unknown
    @subject = "[theseus] [billing] 🟡 unconfirmed HCB transfer #{@transfer.idempotency_key} for #{@profile.organization_name}"
    mail to: LOOPS_RELAY
  end

  def reconcile_ambiguous
    @subject = "[theseus] [billing] 🔴 ambiguous reconciliation for #{@transfer.idempotency_key}, needs a human"
    mail to: LOOPS_RELAY
  end
end
