# frozen_string_literal: true

module Admin
  class UsersToolbox < ApplicationToolbox
    before_action :require_admin!

    tool "Search back-office staff accounts by username or email. Returns paginated list", access: :read, scope: "admin" do
      param :query, :string, "Search term to match against username or email", optional: true
      param :page, :integer, "Page number for pagination", optional: true
    end
    def search
      scope = User.all.order(:username)
      scope = scope.search(params[:query]) if params[:query].present?
      @users = paginate(scope)
    end

    tool "Show full details for a staff account including permissions and defaults", access: :read, scope: "admin" do
      param :user_id, :integer, "User ID"
    end
    def show
      @user = User.find(params[:user_id])
    end

    # NOTE: is_admin and is_warehouse_czar are intentionally not settable via MCP.
    # Privilege escalation should happen in the web UI with full context.
    tool "Create a new back-office staff account", access: :write, scope: "admin" do
      param :username, :string, "Username"
      param :email, :string, "Email address"
      param :can_use_indicia, :boolean, "Can purchase USPS electronic postage for letters", optional: true
      param :can_warehouse, :boolean, "Can create and manage warehouse package orders", optional: true
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

    tool "Update a back-office staff account's profile and permissions", access: :write, scope: "admin" do
      param :user_id, :integer, "User ID"
      param :username, :string, "Username", optional: true
      param :email, :string, "Email address", optional: true
      param :can_use_indicia, :boolean, "Can purchase USPS electronic postage for letters", optional: true
      param :can_warehouse, :boolean, "Can create and manage warehouse package orders", optional: true
      param :can_impersonate_public, :boolean, "Allow public impersonation", optional: true
      param :slack_id, :string, "Slack user ID", optional: true
      param :hca_id, :string, "Hack Club Auth ID", optional: true
      param :icon_url, :string, "Avatar/icon URL", optional: true
      param :home_mid_id, :integer, "Default USPS Mailer ID for letter labels (use postage_mailer_ids to find)", optional: true
      param :home_return_address_id, :integer, "Default return address for new letters (use return_addresses_list to find)", optional: true
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
