class BillingMailer < ApplicationMailer
  NORA = "nora@hackclub.com"

  def settlement_failed
    @ledger_entries = params[:ledger_entries]
    @billing_profile = params[:billing_profile]
    @error = params[:error]
    mail(
      to: NORA,
      subject: "[theseus] billing settlement failed for #{@billing_profile.organization_name}",
    )
  end

  def insufficient_funds
    @ledger_entries = params[:ledger_entries]
    @billing_profile = params[:billing_profile]
    @error = params[:error]
    mail(
      to: NORA,
      subject: "[theseus] ⚠️ INSUFFICIENT FUNDS: #{@billing_profile.organization_name} can't pay for postage",
    )
  end
end
