class USPS::PaymentAccountMailer < GenericTextMailer
  def get_your_eps_racks_up(accounts:)
    @count = accounts.length
    @subject = "[theseus] [usps] #{@count} EPS #{"account".pluralize(@count)} #{"is".pluralize(@count)} broke"
    @recipient = "nora@hackclub.com"
    @accounts = accounts

    mail to: "dinobox@hackclub.com"
  end
end
