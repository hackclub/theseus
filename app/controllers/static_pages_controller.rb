class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :login ]
  # skip_after_action :verify_authorized
  def index
  end

  def login
    flash[:warning] = "Welcome to the login page"
    render :login, layout: false
  end
end
