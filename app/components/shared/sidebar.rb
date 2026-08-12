# frozen_string_literal: true

class Components::Shared::Sidebar < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::CurrentPage

  register_value_helper :request

  def initialize(current_path:)
    @current_path = current_path
  end

  def view_template
    render_mobile_toggle
    render_overlay

    nav(class: "theseus-sidebar", id: "sidebar") do
      div(class: "sidebar-section") do
        nav_link("Home", root_path, exact: true)
        nav_link("Tasks", tasks_path)
      end

      div(class: "sidebar-section") do
        span(class: "sidebar-label") { "Warehouse" }
        nav_link("Orders", warehouse_orders_path)
        nav_link("Batches", warehouse_batches_path)
        nav_link("SKUs", warehouse_skus_path)
        nav_link("Purchase Orders", warehouse_purchase_orders_path)
        nav_link("Templates", warehouse_templates_path)
      end

      div(class: "sidebar-section") do
        span(class: "sidebar-label") { "Mail" }
        nav_link("Letters", letters_path)
        nav_link("Batches", letter_batches_path)
        nav_link("Scanner", scanner_letters_path)
        nav_link("Return Addresses", return_addresses_path)
        nav_link("Queues", letter_queues_path)
      end

      div(class: "sidebar-section") do
        span(class: "sidebar-label") { "Accounting" }
        nav_link("Tags", tags_path)
      end

      div(class: "sidebar-section") do
        span(class: "sidebar-label") { "API" }
        nav_link("API Keys", api_keys_path)
        nav_link("Queues", letter_queues_path)
        nav_link("Docs", api_docs_path)
      end

      div(class: "sidebar-section") do
        span(class: "sidebar-label") { "Settings" }
        nav_link("My Settings", settings_path)
        nav_link("Print", settings_qz_tray_path)
        nav_link("HCB Payment", hcb_payment_accounts_path)
      end

      if current_user&.admin?
        div(class: "sidebar-section") do
          span(class: "sidebar-label") { "Admin" }
          nav_link("Users", admin_users_path)
          nav_link("Common Tags", admin_common_tags_path)
          nav_link("Source Tags", admin_source_tags_path)
          nav_link("USPS Mailer IDs", admin_usps_mailer_ids_path)
          nav_link("USPS Payment Accts", admin_usps_payment_accounts_path)
          nav_link("Good Job", good_job_path)
          nav_link("Blazer", blazer_path)
        end
      end

      if Rails.env.development?
        div(class: "sidebar-section") do
          span(class: "sidebar-label") { "Dev" }
          nav_link("Letter Opener", letter_opener_web_path)
        end
      end
    end

    render_toggle_script
  end

  private

  def nav_link(label, path, exact: false)
    selected = active?(path, exact: exact)
    a(href: path, class: ("selected" if selected)) { label }
  end

  def active?(path, exact: false)
    if exact
      @current_path == path
    else
      @current_path.start_with?(path)
    end
  end

  def render_mobile_toggle
    button(
      class: "sidebar-toggle btn-sm",
      onclick: safe("toggleSidebar()")
    ) { "☰" }
  end

  def render_overlay
    div(class: "sidebar-overlay", onclick: safe("toggleSidebar()"))
  end

  def render_toggle_script
    script do
      raw safe(<<~JS)
        function toggleSidebar() {
          var sb = document.getElementById('sidebar');
          var ov = document.querySelector('.sidebar-overlay');
          if (sb.classList.contains('open')) {
            sb.classList.remove('open');
            ov.classList.remove('open');
          } else {
            sb.classList.add('open');
            ov.classList.add('open');
          }
        }
      JS
    end
  end
end
