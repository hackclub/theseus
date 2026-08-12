# frozen_string_literal: true

module Shortcodes
  class Shortcode < Data.define(:code, :label, :icon, :path, :gate)
    def to_h
      { code:, label:, icon:, path: }
    end

    def visible_to?(user)
      gate.nil? || gate.call(user)
    end
  end

  ADMIN = ->(u) { u&.admin? }
  CZAR  = ->(u) { u&.warehouse_czar? }

  class << self
    include Rails.application.routes.url_helpers

    def all(user = nil)
      registry.select { |s| s.visible_to?(user) }
    end

    def public_id_prefixes
      {
        "ltr" => { model: "Letter", path: "/back_office/letters" },
        "bat" => { model: "Batch", path: "/back_office/letter/batches" },
        "pkg" => { model: "Package", path: "/back_office/warehouse/orders" },
        "usr" => { model: "User", path: "/back_office/admin/users" },
        "ind" => { model: "Indicium", path: "/back_office/inspect/indicia" },
        "mtr" => { model: "MTR Event", path: "/back_office/inspect/iv_mtr_events" },
        "wot" => { model: "Order Template", path: "/back_office/warehouse/templates" },
      }
    end

    def search_scopes
      [
        { key: "letters", label: "Letters", icon: "◇" },
        { key: "orders", label: "Warehouse Orders", icon: "⊡" },
      ]
    end

    def code_for(path)
      by_path[path]
    end

    private

    def registry
      @registry ||= [
        Shortcode.new(code: "HOME", label: "Home", icon: "⌂", path: root_path, gate: nil),

        # warehouse
        Shortcode.new(code: "WORD", label: "Warehouse Orders", icon: "⊡", path: warehouse_orders_path, gate: nil),
        Shortcode.new(code: "WBAT", label: "Warehouse Batches", icon: "⊞", path: warehouse_batches_path, gate: nil),
        Shortcode.new(code: "SKUS", label: "SKUs", icon: "▦", path: warehouse_skus_path, gate: nil),
        Shortcode.new(code: "PORD", label: "Purchase Orders", icon: "⊟", path: warehouse_purchase_orders_path, gate: nil),
        Shortcode.new(code: "WTPL", label: "Order Templates", icon: "⎘", path: warehouse_templates_path, gate: nil),
        Shortcode.new(code: "WNEW", label: "New Warehouse Order", icon: "⊡", path: new_warehouse_order_path, gate: nil),
        Shortcode.new(code: "PONE", label: "New Purchase Order", icon: "⊟", path: new_warehouse_purchase_order_path, gate: nil),
        Shortcode.new(code: "WTNE", label: "New Order Template", icon: "⎘", path: new_warehouse_template_path, gate: nil),
        Shortcode.new(code: "CZAR", label: "Approval Queue", icon: "⊙", path: warehouse_approvals_path, gate: CZAR),

        # mail
        Shortcode.new(code: "MAIL", label: "Letters", icon: "◇", path: letters_path, gate: nil),
        Shortcode.new(code: "LBAT", label: "Letter Batches", icon: "⊞", path: letter_batches_path, gate: nil),
        Shortcode.new(code: "SCAN", label: "Mail Scanner", icon: "↯", path: scanner_letters_path, gate: nil),
        Shortcode.new(code: "LRET", label: "Return Addresses", icon: "↩", path: return_addresses_path, gate: nil),
        Shortcode.new(code: "LQUE", label: "Letter Queues", icon: "☰", path: letter_queues_path, gate: nil),
        Shortcode.new(code: "LNEW", label: "New Letter", icon: "◇", path: new_letter_path, gate: nil),
        Shortcode.new(code: "LBNE", label: "New Letter Batch", icon: "⊞", path: new_letter_batch_path, gate: nil),
        Shortcode.new(code: "LRNE", label: "New Return Address", icon: "↩", path: new_return_address_path, gate: nil),

        # rest
        Shortcode.new(code: "TAGS", label: "Tags", icon: "⏿", path: tags_path, gate: nil),
        Shortcode.new(code: "KEYS", label: "API Keys", icon: "⚿", path: api_keys_path, gate: nil),
        Shortcode.new(code: "KNEW", label: "New API Key", icon: "⚿", path: new_api_key_path, gate: nil),
        Shortcode.new(code: "DOCS", label: "API Docs", icon: "≡", path: "/back_office/api-docs", gate: nil),
        Shortcode.new(code: "FIND", label: "ID Lookup", icon: "⌕", path: public_ids_path, gate: nil),
        Shortcode.new(code: "TASK", label: "My Tasks", icon: "◆", path: tasks_path, gate: nil),
        Shortcode.new(code: "PROB", label: "Problems", icon: "⊘", path: problems_path, gate: nil),
        Shortcode.new(code: "SETT", label: "My Settings", icon: "⚙", path: "/back_office/my/settings", gate: nil),

        # admin
        Shortcode.new(code: "JOBS", label: "Good Job", icon: "⊕", path: "/back_office/good_job", gate: ADMIN),
        Shortcode.new(code: "FIRE", label: "Blazer", icon: "≋", path: "/back_office/blazer", gate: ADMIN),
        Shortcode.new(code: "AUSR", label: "Admin Users", icon: "⊛", path: "/back_office/admin/users", gate: ADMIN),
        Shortcode.new(code: "ACTG", label: "Common Tags", icon: "⏿", path: "/back_office/admin/common_tags", gate: ADMIN),
        Shortcode.new(code: "ASTG", label: "Source Tags", icon: "⊙", path: "/back_office/admin/source_tags", gate: ADMIN),
        Shortcode.new(code: "AMID", label: "USPS Mailer IDs", icon: "⊚", path: "/back_office/admin/usps/mailer_ids", gate: ADMIN),
        Shortcode.new(code: "AEPS", label: "USPS Payment Accts", icon: "⊛", path: "/back_office/admin/usps/payment_accounts", gate: ADMIN),
      ]
    end

    def by_path
      @by_path ||= registry.each_with_object({}) { |s, h| h[s.path] = s.code }
    end

    public

    def kbar_data_for(user)
      {
        shortcuts: all(user).map(&:to_h),
        prefixes: public_id_prefixes,
        searchScopes: search_scopes,
      }.to_json
    end
  end
end
