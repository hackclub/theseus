# frozen_string_literal: true

module Admin
  class UsersToolbox < ApplicationToolbox
    before_action :require_admin!

    tool "Search users by username or email", access: :read, scope: "admin" do
      param :query, :string, "Search term to match against username or email", optional: true
      param :page, :integer, "Page number for pagination", optional: true
    end
    def search
      scope = User.all.order(:username)
      if params[:query].present?
        q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query])}%"
        scope = scope.where("username ILIKE ? OR email ILIKE ?", q, q)
      end
      @users = paginate(scope)
    end

    tool "Show full details for a user", access: :read, scope: "admin" do
      param :user_id, :integer, "User ID"
    end
    def show
      @user = User.find(params[:user_id])
    end

    # NOTE: is_admin and is_warehouse_czar are intentionally not settable via MCP.
    # Privilege escalation should happen in the web UI with full context.
    tool "Create a new user", access: :write, scope: "admin" do
      param :username, :string, "Username"
      param :email, :string, "Email address"
      param :can_use_indicia, :boolean, "Allow indicia usage", optional: true
      param :can_warehouse, :boolean, "Allow warehouse access", optional: true
      param :can_impersonate_public, :boolean, "Allow public impersonation", optional: true
      param :slack_id, :string, "Slack user ID", optional: true
      param :hca_id, :string, "Hack Club Auth ID", optional: true
      param :icon_url, :string, "Avatar/icon URL", optional: true
    end
    def create
      @user = User.create!(
        params.permit(
          :username, :email, :can_use_indicia,
          :can_warehouse, :can_impersonate_public, :slack_id, :hca_id, :icon_url
        )
      )
      render :show
    end

    tool "Update an existing user", access: :write, scope: "admin" do
      param :user_id, :integer, "User ID"
      param :username, :string, "Username", optional: true
      param :email, :string, "Email address", optional: true
      param :can_use_indicia, :boolean, "Allow indicia usage", optional: true
      param :can_warehouse, :boolean, "Allow warehouse access", optional: true
      param :can_impersonate_public, :boolean, "Allow public impersonation", optional: true
      param :slack_id, :string, "Slack user ID", optional: true
      param :hca_id, :string, "Hack Club Auth ID", optional: true
      param :icon_url, :string, "Avatar/icon URL", optional: true
      param :home_mid_id, :integer, "Home USPS Mailer ID", optional: true
      param :home_return_address_id, :integer, "Home return address ID", optional: true
    end
    def update
      @user = User.find(params[:user_id])
      @user.update!(
        params.permit(
          :username, :email, :can_use_indicia,
          :can_warehouse, :can_impersonate_public, :slack_id, :hca_id, :icon_url,
          :home_mid_id, :home_return_address_id
        )
      )
      render :show
    end
  end
end
