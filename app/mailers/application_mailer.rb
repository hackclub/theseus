class ApplicationMailer < ActionMailer::Base
  default from: "team@hackclub.com"
  layout "text_mailer"
end
