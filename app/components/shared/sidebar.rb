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
      nav_link("Home", root_path, exact: true)
      div("is-": "separator")

      section_label("Warehouse")
      nav_link("Orders", warehouse_orders_path)
      nav_link("Batches", warehouse_batches_path)
      nav_link("SKUs", warehouse_skus_path)
      nav_link("Purchase Orders", warehouse_purchase_orders_path)
      nav_link("Templates", warehouse_templates_path)
      div("is-": "separator")

      section_label("Mail")
      nav_link("Letters", letters_path)
      nav_link("Batches", letter_batches_path)
      nav_link("Scanner", scanner_letters_path)
      nav_link("Return Addresses", return_addresses_path)
      nav_link("Queues", letter_queues_path)
      div("is-": "separator")

      section_label("Accounting")
      nav_link("Tags", tags_path)
      div("is-": "separator")

      section_label("API")
      nav_link("API Keys", api_keys_path)
      nav_link("Queues", letter_queues_path)
      nav_link("Docs", api_docs_path)
      div("is-": "separator")

      section_label("Settings")
      nav_link("Print", settings_qz_tray_path)
      nav_link("HCB Payment", hcb_payment_accounts_path)

      if current_user&.admin?
        div("is-": "separator")
        section_label("Admin")
        nav_link("Good Job", good_job_path)
        nav_link("Admin Panel", admin_root_path)
        nav_link("Blazer", blazer_path)
      end

      if Rails.env.development?
        div("is-": "separator")
        section_label("Dev")
        nav_link("Letter Opener", letter_opener_web_path)
      end
    end

    render_toggle_script
  end

  private

  def section_label(text)
    span(
      style: "display: block; padding: 0.25lh 1ch 0; font-size: 0.8em; text-transform: uppercase; letter-spacing: 0.1ch; color: var(--foreground2);"
    ) { text }
  end

  def nav_link(label, path, exact: false)
    selected = active?(path, exact: exact)
    a(
      href: path,
      data_navigable_item: true,
      class: ("selected" if selected),
      style: "display: block; padding: 0 1ch; color: var(--foreground#{selected ? '0' : '2'}); text-decoration: none; #{'font-weight: bold; background: var(--background1);' if selected}"
    ) { label }
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
      class: "sidebar-toggle",
      "size-": "small",
      onclick: safe("toggleSidebar()")
    ) { "☰" }
  end

  def render_overlay
    div(class: "sidebar-overlay", onclick: safe("toggleSidebar()"))
  end

  def render_toggle_script
    script do
      plain(<<~JS.html_safe)
        function toggleSidebar() {
          var sb = document.getElementById('sidebar');
          var ov = document.querySelector('.sidebar-overlay');
          if (sb.classList.contains('open')) {
            sb.classList.remove('open');
            ov.style.display = 'none';
          } else {
            sb.classList.add('open');
            ov.style.display = 'block';
          }
        }
      JS
    end
  end
end
