class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized

  helper_method :current_user, :user_signed_in?

  before_action :authenticate_user!, :set_honeybadger_context

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    !!current_user
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to login_path, alert: ("you need to be logged in!" unless request.env["PATH_INFO"] == "/back_office")
    end
  end

  def set_honeybadger_context
    Honeybadger.context({
      user_id: current_user&.id,
      user_email: current_user&.email,
    })
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
