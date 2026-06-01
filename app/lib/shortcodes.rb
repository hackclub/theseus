# frozen_string_literal: true

module Shortcodes
  class Shortcode < Data.define(:code, :label, :icon, :path, :admin_only)
    def to_h
      { code:, label:, icon:, path: }
    end
  end

  class << self
    include Rails.application.routes.url_helpers

    def all(user = nil)
      shortcuts = [
        Shortcode.new(code: "HOME", label: "Home", icon: "⌂", path: root_path, admin_only: false),

        # warehouse
        Shortcode.new(code: "WORD", label: "Warehouse Orders", icon: "⊡", path: warehouse_orders_path, admin_only: false),
        Shortcode.new(code: "WBAT", label: "Warehouse Batches", icon: "⊞", path: warehouse_batches_path, admin_only: false),
        Shortcode.new(code: "SKUS", label: "SKUs", icon: "▦", path: warehouse_skus_path, admin_only: false),
        Shortcode.new(code: "PORD", label: "Purchase Orders", icon: "⊟", path: warehouse_purchase_orders_path, admin_only: false),
        Shortcode.new(code: "WTPL", label: "Order Templates", icon: "⎘", path: warehouse_templates_path, admin_only: false),
        Shortcode.new(code: "WNEW", label: "New Warehouse Order", icon: "⊡", path: new_warehouse_order_path, admin_only: false),
        Shortcode.new(code: "PONE", label: "New Purchase Order", icon: "⊟", path: new_warehouse_purchase_order_path, admin_only: false),
        Shortcode.new(code: "WTNE", label: "New Order Template", icon: "⎘", path: new_warehouse_template_path, admin_only: false),

        # mail
        Shortcode.new(code: "MAIL", label: "Letters", icon: "◇", path: letters_path, admin_only: false),
        Shortcode.new(code: "LBAT", label: "Letter Batches", icon: "⊞", path: letter_batches_path, admin_only: false),
        Shortcode.new(code: "SCAN", label: "Mail Scanner", icon: "↯", path: scanner_letters_path, admin_only: false),
        Shortcode.new(code: "LRET", label: "Return Addresses", icon: "↩", path: return_addresses_path, admin_only: false),
        Shortcode.new(code: "LQUE", label: "Letter Queues", icon: "☰", path: letter_queues_path, admin_only: false),
        Shortcode.new(code: "LNEW", label: "New Letter", icon: "◇", path: new_letter_path, admin_only: false),
        Shortcode.new(code: "LBNE", label: "New Letter Batch", icon: "⊞", path: new_letter_batch_path, admin_only: false),
        Shortcode.new(code: "LRNE", label: "New Return Address", icon: "↩", path: new_return_address_path, admin_only: false),

        # rest
        Shortcode.new(code: "TAGS", label: "Tags", icon: "⏿", path: tags_path, admin_only: false),
        Shortcode.new(code: "KEYS", label: "API Keys", icon: "⚿", path: api_keys_path, admin_only: false),
        Shortcode.new(code: "KNEW", label: "New API Key", icon: "⚿", path: new_api_key_path, admin_only: false),
        Shortcode.new(code: "DOCS", label: "API Docs", icon: "≡", path: "/back_office/api-docs", admin_only: false),
        Shortcode.new(code: "FIND", label: "ID Lookup", icon: "⌕", path: public_ids_path, admin_only: false),
        Shortcode.new(code: "TASK", label: "My Tasks", icon: "◆", path: tasks_path, admin_only: false),
        Shortcode.new(code: "PROB", label: "Problems", icon: "⊘", path: problems_path, admin_only: false),

        # admin
        Shortcode.new(code: "JOBS", label: "Good Job", icon: "⊕", path: "/back_office/good_job", admin_only: true),
        Shortcode.new(code: "ADMN", label: "Admin Panel", icon: "⊛", path: "/back_office/admin", admin_only: true),
        Shortcode.new(code: "FIRE", label: "Blazer", icon: "≋", path: "/back_office/blazer", admin_only: true),
      ]

      if user&.admin?
        shortcuts
      else
        shortcuts.reject(&:admin_only)
      end
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

    def by_path
      @by_path ||= all.each_with_object({}) { |s, h| h[s.path] = s.code }
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
