module Public
  class ApplicationController < ActionController::Base
    include Pundit::Authorization

    layout "public"

    before_action do
      Honeybadger.context({
        user_id: current_public_user&.id,
        user_email: current_public_user&.email,
        real_user_id: current_user&.id,
        real_user_email: current_user&.email,
        impersonator_user_id: session[:public_impersonator_user_id],
      })
    end

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

    rescue_from Pundit::NotAuthorizedError do |e|
      flash[:error] = "hey, you can't do that!"
      redirect_to public_root_path
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      flash[:error] = "sorry, couldn't find that page!"
      redirect_to public_root_path
    end
  end
end
