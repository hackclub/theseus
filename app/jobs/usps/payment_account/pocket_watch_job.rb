class USPS::PaymentAccount::PocketWatchJob < ApplicationJob
  THRESHOLD = 50 # 50 bucks seems reasonable?

  queue_as :default

  def perform(*args)
    broke_accounts = []

    USPS::PaymentAccount.all.each do |acct|
      broke_accounts << acct unless acct.check_funds_available(THRESHOLD)
    end

    USPS::PaymentAccountMailer.with(accounts: broke_accounts).get_your_eps_racks_up.deliver_later
  end
end
