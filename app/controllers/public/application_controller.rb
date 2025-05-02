module Public
  class ApplicationController < ActionController::Base
    include Pundit::Authorization

    layout "public"

    helper_method :current_user, :current_public_user, :public_user_signed_in?, :authenticate_public_user!, :impersonating?

    # DO NOT USE (in most cases :-P)
    def current_user
      @current_user ||= ::User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def current_public_user
      @current_public_user ||= Public::User.find_by(id: session[:public_user_id]) if session[:public_user_id]
    end

    def public_user_signed_in?
      !!current_public_user
    end

    def authenticate_public_user!
      unless public_user_signed_in?
        redirect_to public_login_path, alert: ("you need to be logged in!" unless request.env["PATH_INFO"] == "/")
      end
    end

    def impersonating?
      !!session[:public_impersonator_user_id]
    end

    rescue_from Pundit::NotAuthorizedError do
      flash[:error] = "hey, you can't do that!"
      redirect_to root_path
    end
  end
end