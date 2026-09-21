# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    skip_after_action :verify_authorized

    def index
      @users = User.left_joins(:letters, :warehouse_orders)
                   .select("users.*, COUNT(DISTINCT letters.id) AS letter_count, COUNT(DISTINCT warehouse_orders.id) AS warehouse_order_count")
                   .group("users.id")
                   .order(:username)
      @users = @users.where("username ILIKE :q OR email ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
      render Views::Admin::Users::Index.new(users: @users)
    end

    def new
      render Views::Admin::Users::New.new(user: User.new)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_user_path(@user), notice: "User created."
      else
        render Views::Admin::Users::New.new(user: @user), status: :unprocessable_entity
      end
    end

    def show
      render Views::Admin::Users::Show.new(user: resource)
    end

    def edit
      render Views::Admin::Users::Edit.new(user: resource)
    end

    def update
      if resource.update(user_params)
        redirect_to admin_user_path(resource), notice: "User updated."
      else
        render Views::Admin::Users::Edit.new(user: resource), status: :unprocessable_entity
      end
    end

    def flip
      feature = params[:flag].presence
      state = params[:state] == "true"

      if feature.nil?
        return redirect_to admin_user_path(resource), alert: "No feature flag given."
      end

      if state
        Flipper.enable_actor(feature, resource)
      else
        Flipper.disable_actor(feature, resource)
      end

      redirect_to admin_user_path(resource), notice: "#{feature}: #{state ? 'enabled' : 'disabled'} for #{resource.username}"
    end

    private

    def resource = @resource ||= User.find(params[:id])

    def user_params
      params.require(:user).permit(
        :username, :email, :is_admin, :is_warehouse_czar, :can_use_indicia,
        :can_warehouse, :can_impersonate_public, :slack_id, :hca_id, :icon_url,
        :home_mid_id, :home_return_address_id
      )
    end
  end
end
