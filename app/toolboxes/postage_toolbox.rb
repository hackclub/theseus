class PostageToolbox < ApplicationToolbox
  tool "List USPS payment accounts with name and account type", access: :read do
  end
  def payment_accounts
    @payment_accounts = USPS::PaymentAccount.all
  end

  tool "List USPS mailer IDs with MID and CRID", access: :read do
  end
  def mailer_ids
    @mailer_ids = USPS::MailerId.all
  end

  tool "List billing profiles for the current user", access: :read do
  end
  def billing_profiles
    @billing_profiles = current_user.billing_profiles
  end

  tool "Show indicium details including postage, fees, cost, SKU, and mailing date (admin only)", access: :read, scope: "admin" do
    param :indicium_id, :string, "Indicium ID — accepts ind!HASH, hackapost!/HASH, or just the hashid"
  end
  def indicium_info
    require_admin!
    result = PublicIdResolver.resolve(params[:indicium_id])
    if result&.record.is_a?(USPS::Indicium)
      @indicium = result.record
    else
      # Bare hashid or numeric ID fallback
      @indicium = USPS::Indicium.find_by_hashid(params[:indicium_id]) ||
                  USPS::Indicium.find(params[:indicium_id])
    end
  end
end
