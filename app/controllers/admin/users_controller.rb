# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    skip_after_action :verify_authorized

    def index
      @users = User.all.order(:username)
      @users = @users.where("username ILIKE :q OR email ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
      render Views::Admin::Users::Index.new(users: @users)
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
