class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include HCBConnectionCheck
  after_action :verify_authorized

  helper_method :current_user, :user_signed_in?, :impersonating?

  before_action :authenticate_user!, :set_sentry_context, :set_paper_trail_info

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def impersonating? = !!session[:impersonator_user_id]

  def user_signed_in?
    !!current_user
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to login_path, alert: ("you need to be logged in!" unless request.env["PATH_INFO"] == "/back_office")
    end
  end

  def set_sentry_context
    Sentry.set_user(id: current_user&.id, email: current_user&.email)
  end

  def set_paper_trail_info
    PaperTrail.request.controller_info = { ip: request.remote_ip }
  end

  rescue_from Pundit::NotAuthorizedError do |e|
    flash[:error] = "you don't seem to be authorized – ask nora?"
    redirect_to root_path
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    flash[:error] = "sorry, couldn't find that object... (404)"
    redirect_to root_path
  end
end
