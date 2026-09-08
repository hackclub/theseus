Toolchest.configure do |config|
  config.server_name = "Theseus"
  # config.server_description = ""
  config.auth = :oauth
  config.mount_path = "/mcp"

  config.login_path = "/login"

  # Identify the logged-in user during the OAuth consent screen.
  # Return a user object, or nil to redirect to login_path.
  config.current_user_for_oauth do |request|
    # Example with Devise:
    #   request.env["warden"]&.user
    # Example with a session:
    #   User.find_by(id: request.session[:user_id])
  end

  # Resolve the token to a user (or anything). Available as auth.resource_owner in toolboxes.
  config.authenticate do |token|
    # User.find(token.resource_owner_id)
  end

  # config.scopes = {
  #   "posts:read"  => "View blog posts",
  #   "posts:write" => "Create and modify blog posts"
  # }

  # Tool naming strategy: :underscored (default), :dotted, :slashed, or a lambda
  # config.tool_naming = :underscored

  # Filter tools/list by authenticated scopes (default: true)
  # config.filter_tools_by_scope = true
end
