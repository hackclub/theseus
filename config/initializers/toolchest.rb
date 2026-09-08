Toolchest.configure do |config|
  config.server_name = "Theseus"
  config.server_description = "Mail & fulfillment management for Hack Club"
  config.auth = :oauth
  config.mount_path = "/mcp"
  config.access_token_expires_in = 30.days

  Toolchest.base_controller = "ToolchestController"

  config.login_path = "/back_office/login"

  config.server_instructions = <<~INSTRUCTIONS
    You are an assistant for Theseus, Hack Club's mail and warehouse management platform.
    You can search, create, and manage letters, warehouse orders, purchase orders, SKUs, and users.

    Start with theseus_whoami to understand who you are and what you can do.
    Use theseus_dashboard to see what needs attention.
    Use theseus_lookup to resolve any ID (public IDs, hackapost codes, tracking numbers).
    Always search before creating to avoid duplicates.

    DRAFTS ARE FREE, DISPATCH COSTS MONEY.
    Creating letters and warehouse orders makes drafts — that's safe, do it freely.
    But sending to the warehouse (warehouse_orders_send_to_warehouse), dispatching POs
    to Zenventory (purchase_orders_send_to_zenventory), and canceling orders
    (warehouse_orders_cancel) have real-world consequences: they cost money, ship
    physical goods, or are irreversible. NEVER call these unless the user has
    explicitly asked you to send/dispatch/cancel. "Draft this order" does NOT mean
    "send it." Wait for "ok send it" or "ship it" or "dispatch" — something unambiguous.
  INSTRUCTIONS

  # Only back office users (the User model, NOT Public::User) can see the consent screen.
  # This is the first gate — before they even see "authorize this app?"
  config.authorize_link do |user|
    user.is_a?(User) && user.persisted?
  end

  config.current_user_for_oauth do |request|
    User.find_by(id: request.session[:user_id])
  end

  # Token → user. Fail hard if the user doesn't exist or isn't a real back office user.
  config.authenticate do |token|
    user = User.find_by(id: token.resource_owner_id)
    raise ActiveRecord::RecordNotFound, "User not found" unless user
    user
  end

  # Every token gets theseus:read so the agent can at least orient itself.
  config.required_scopes = ["theseus:read"]

  # Consent screen shows checkboxes — users can uncheck scopes they don't want to grant.
  # theseus:read is required (always checked, can't uncheck — the agent needs orientation).
  config.optional_scopes = true

  # Scope names match toolchest convention: last segment of controller_name.
  # Warehouse::OrdersToolbox → "orders:*", not "warehouse_orders:*"
  config.scopes = {
    "theseus:read" => "Identity, dashboard, and ID lookup",
    "letters:read" => "View and search letters",
    "letters:write" => "Create, edit, and manage letters",
    "orders:read" => "View and search warehouse orders",
    "orders:write" => "Create, edit, and dispatch warehouse orders",
    "purchase_orders:read" => "View and search purchase orders",
    "purchase_orders:write" => "Create, edit, and manage purchase orders",
    "skus:read" => "View SKU inventory",
    "skus:write" => "Edit SKU details",
    "return_addresses:read" => "View return addresses",
    "return_addresses:write" => "Create and edit return addresses",
    "letter_queues:read" => "View letter queues",
    "letter_queues:write" => "Create queues and make batches",
    "tags:read" => "View and search tags",
    "warehouse_templates:read" => "View warehouse templates",
    "postage:read" => "View postage and indicia info",
    "warehouse_czar" => "Approve POs and dispatch to Zenventory",
    "admin" => "Admin operations (user management, system config)",
  }

  WAREHOUSE_SCOPES = %w[
    orders:read orders:write
    purchase_orders:read purchase_orders:write
    skus:read skus:write
    warehouse_templates:read
    warehouse_czar
  ].freeze

  # Gate scopes by user permissions:
  # - Warehouse scopes only for warehouse users
  # - Czar scope only for warehouse czars
  # - Admin scope only for admins
  config.allowed_scopes_for do |user, requested_scopes|
    allowed = requested_scopes.dup
    allowed -= ["admin"] unless user.admin?
    allowed -= ["warehouse_czar"] unless user.warehouse_czar? || user.admin?
    allowed -= WAREHOUSE_SCOPES unless user.can_warehouse? || user.admin?
    allowed
  end

  # TODO: enable once toolchest >= 0.4 is released (attr exists in local src but not 0.3.7)
  # config.dns_rebinding_protection = true
  # config.allowed_origins = ["https://theseus.hackclub.com"]
end
