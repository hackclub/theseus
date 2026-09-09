class BillingMailer < ApplicationMailer
  NORA = "nora@hackclub.com"

  before_action { @transfer = params[:transfer]; @profile = @transfer.billing_profile }

  def transfer_failed
    mail(to: NORA, subject: "[theseus] billing transfer failed for #{@profile.organization_name}")
  end

  def insufficient_funds
    mail(to: NORA, subject: "[theseus] ⚠️ INSUFFICIENT FUNDS: #{@profile.organization_name} can't pay $#{"%.2f" % @transfer.amount}")
  end

  def transfer_unknown
    mail(to: NORA, subject: "[theseus] 🟡 unconfirmed HCB transfer #{@transfer.idempotency_key} for #{@profile.organization_name}")
  end

  def reconcile_ambiguous
    mail(to: NORA, subject: "[theseus] 🔴 ambiguous reconciliation for #{@transfer.idempotency_key} — needs a human")
  end
end
