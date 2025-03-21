class ApplicationController < ActionController::Base
  include Pundit::Authorization
  # after_action :verify_authorized

  helper_method :current_user, :user_signed_in?

  before_action :authenticate_user!

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    !!current_user
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to login_path, alert: ("you need to be logged in!" unless request.env["PATH_INFO"] == "/")
    end
  end
end
