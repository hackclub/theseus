class Public::LoginCodeMailer < ApplicationMailer
  def send_login_code(email, login_code)
    @recipient = email
    @login_code_url = login_code_url login_code

    mail to: @recipient
  end
end
