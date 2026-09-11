module Public
  class SessionsController < ApplicationController
    def send_email
      begin
        @email = params.require(:email)
      rescue ActionController::ParameterMissing
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

      if Rails.env.production?
        SendLoginEmailJob.perform_later(@email)
      else
        SendLoginEmailJob.perform_now(@email)
      end
    end

    def login_code
      valid_code = LoginCode.where(token: params[:token], used_at: nil)
        .where("expires_at > ?", Time.current)
        .first

      if valid_code
        valid_code.mark_used!
        session[:public_user_id] = valid_code.user_id
        redirect_to public_root_path, notice: "you're in!"
      else
        redirect_to public_root_path, alert: "invalid or expired sign-in link...?"
      end
    end

    def hackclub_callback
      auth = request.env["omniauth.auth"]

      if auth.nil?
        redirect_to public_login_path, alert: "authentication failed"
        return
      end

      begin
        @user = Public::User.from_hack_club_auth(auth)
      rescue => e
        Rails.logger.error "Error creating public user from HCA: #{e.message}"
        event_id = Sentry.capture_exception(e)&.event_id
        redirect_to public_login_path, alert: "error authenticating! (error: #{event_id})"
        return
      end

      if @user&.persisted?
        session[:public_user_id] = @user.id
        redirect_to public_root_path, notice: "you're in!"
      else
        redirect_to public_login_path, alert: "something went wrong..."
      end
    end

    def destroy
      session[:public_user_id] = nil
      session[:public_impersonator_user_id] = nil
      redirect_to public_root_path, notice: "signed out!"
    end
  end
end
