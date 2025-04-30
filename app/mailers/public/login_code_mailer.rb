# this is a loops mailer until they unfreeze our account
class Public::LoginCodeMailer < GenericTextMailer
  def send_login_code(email, login_code)
    @subject = "(hack club) here's your mail login link!"
    @recipient = email
    @login_code_url = login_code_url login_code

    mail to: @recipient
  end
end
