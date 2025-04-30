module Public
  class SendLoginEmailJob < ApplicationJob
    queue_as :default

    def perform(email)
      code = Public::User.find_or_create_by!(email:).create_login_code
      LoginCodeMailer.send_login_code(email, code).deliver_later
    end
  end
end