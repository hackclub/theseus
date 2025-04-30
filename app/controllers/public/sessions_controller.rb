module Public
  class SessionsController < ApplicationController
    def send_email
      begin
        @email = params.require(:email)
      rescue ActionController::ParameterMissing => e
        @error = "you do need to enter an email address...."
        return render "public/static_pages/login"
      end

      if @email.ends_with?("hack.af")
        @error = "come on, is that your <b>real</b> email? say hi to orpheus for me".html_safe
        return render "public/static_pages/login"
      end

      address = ValidEmail2::Address.new(@email)

      unless address.valid?
        @error = "that isn't shaped like an email..."
        return render "public/static_pages/login"
      end
    end
  end
end