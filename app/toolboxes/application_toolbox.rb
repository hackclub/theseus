class ApplicationToolbox < Toolchest::Toolbox
  # Shared behavior for all toolboxes.
  # Like ApplicationController, but for MCP tools.
  #
  # auth returns a Toolchest::AuthContext with:
  #   auth.resource_owner  — whatever your authenticate block returns
  #   auth.scopes          — token scopes (always preserved)
  #   auth.token           — the raw token record
  def current_user = auth&.resource_owner
end
