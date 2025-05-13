class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  skip_after_action :verify_authorized

  def new
    redirect_uri = url_for(action: :create, only_path: false)
    Rails.logger.info "Starting Slack OAuth flow with redirect URI: #{redirect_uri}"
    redirect_to User.authorize_url(redirect_uri),
                host: "https://slack.com",
                allow_other_host: true
  end

  def create
    redirect_uri = url_for(action: :create, only_path: false)

    if params[:error].present?
      Rails.logger.error "Slack OAuth error: #{params[:error]}"
      uuid = Honeybadger.notify("Slack OAuth error: #{params[:error]}")
      redirect_to login_path, alert: "failed to authenticate with Slack! (error: #{uuid})"
      return
    end

    begin
      @user = User.from_slack_token(params[:code], redirect_uri)
    rescue => e
      Rails.logger.error "Error creating user from Slack data: #{e.message}"
      uuid = Honeybadger.notify(e)
      redirect_to login_path, alert: "error authenticating! (error: #{uuid})"
      return
    end

    if @user&.persisted?
      session[:user_id] = @user.id
      flash[:success] = "welcome aboard!"
      redirect_to root_path
    else
      Rails.logger.error "Failed to create/update user from Slack data"
      redirect_to login_path, alert: "are you sure you should be here?"
    end
  end

  def impersonate
    unless current_user.admin?
      redirect_to root_path, alert: "you are not authorized to impersonate users. this incident has been reported :-P"
      Honeybadger.notify("Impersonation attempt by #{current_user.username} to #{params[:id]}")
      return
    end

    session[:impersonator_user_id] ||= current_user.id
    user = User.find(params[:id])
    session[:user_id] = user.id
    flash[:success] = "hey #{user.username}! how's it going? nice 'stache and glasses!"
    redirect_to root_path
  end

  def stop_impersonating
    session[:user_id] = session[:impersonator_user_id]
    session[:impersonator_user_id] = nil
    redirect_to root_path, notice: "welcome back, 007!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "bye, see you next time!"
  end
end
