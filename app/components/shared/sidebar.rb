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
      render_brand
      render_main_navigation
      render_admin_section if current_user&.admin?
      render_dev_tools_section if Rails.env.development?
    end

    render_toggle_script
  end

  private

  def render_brand
    div(class: "sidebar-brand") do
      strong { "Theseus" }
      if Rails.env.development?
        whitespace
        sup { Rails.env }
      end
    end
  end

  def render_main_navigation
    render_section("Navigation", open: true) do
      nav_link("Home", root_path, exact: true)
    end

    render_section("Warehouse") do
      nav_link("Orders", warehouse_orders_path)
      nav_link("Batches", warehouse_batches_path)
      nav_link("SKUs", warehouse_skus_path)
      nav_link("Purchase Orders", warehouse_purchase_orders_path)
      nav_link("Order Templates", warehouse_templates_path)
    end

    render_section("Mail") do
      nav_link("Letters", letters_path)
      nav_link("Batches", letter_batches_path)
      nav_link("Mail Scanner", scanner_letters_path)
      nav_link("Return Addresses", return_addresses_path)
      nav_link("Queues", letter_queues_path)
    end

    render_section("Accounting") do
      nav_link("Tags", tags_path)
    end

    render_section("API") do
      nav_link("API Keys", api_keys_path)
      nav_link("Letter Queues", letter_queues_path)
      nav_link("Docs", api_docs_path)
    end

    render_section("Settings") do
      nav_link("Print Settings", settings_qz_tray_path)
      nav_link("HCB Payment", hcb_payment_accounts_path)
    end
  end

  def render_admin_section
    render_section("Admin") do
      nav_link("Good Job", good_job_path)
      nav_link("Admin Panel", admin_root_path)
      nav_link("Blazer", blazer_path)
    end
  end

  def render_dev_tools_section
    render_section("Dev Tools") do
      nav_link("Letter Opener", letter_opener_web_path)
    end
  end

  def render_section(title, open: true, &block)
    details(open: open) do
      summary { title }
      ul(&block)
    end
  end

  def nav_link(label, path, exact: false)
    selected = active?(path, exact: exact)
    li do
      a(
        href: path,
        data_navigable_item: true,
        class: ("selected" if selected)
      ) { label }
    end
  end

  def active?(path, exact: false)
    if exact
      @current_path == path
    else
      @current_path.start_with?(path)
    end
  end

  def render_mobile_toggle
    button(class: "sidebar-toggle", onclick: safe("toggleSidebar()"), "aria-label": "Toggle sidebar") do
      svg(
        width: "24",
        height: "24",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: "2.5",
        stroke_linecap: "round",
        stroke_linejoin: "round"
      ) do |s|
        s.line(x1: "4", y1: "6", x2: "20", y2: "6")
        s.line(x1: "4", y1: "12", x2: "20", y2: "12")
        s.line(x1: "4", y1: "18", x2: "20", y2: "18")
      end
    end
  end

  def render_overlay
    div(class: "sidebar-overlay", onclick: safe("toggleSidebar()"))
  end

  def render_toggle_script
    script do
      raw safe <<~JS
        function toggleSidebar() {
          const sidebar = document.getElementById('sidebar');
          const overlay = document.querySelector('.sidebar-overlay');
          sidebar.classList.toggle('mobile-open');
          overlay.classList.toggle('active');
        }
      JS
    end
  end
end
