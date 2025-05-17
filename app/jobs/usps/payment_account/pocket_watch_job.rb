class USPS::PaymentAccount::PocketWatchJob < ApplicationJob
  THRESHOLD = 50 # 50 bucks seems reasonable?

  queue_as :default

  def perform(*args)
    broke_accounts = []

    USPS::PaymentAccount.all.each do |acct|
      if acct.ach?
        Rails.logger.info("skipping pacc #{acct.id} because it's ach")
        next
      end
      broke_accounts << acct unless acct.check_funds_available(THRESHOLD)
    end

    USPS::PaymentAccountMailer.get_your_eps_racks_up(accounts: broke_accounts).deliver_later if broke_accounts.any?
  end
end
