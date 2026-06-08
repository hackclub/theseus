# frozen_string_literal: true

class Components::StaticPages::Home < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(stats:)
    @stats = stats
  end

  def view_template
    toolbar
    needs_attention_section
    this_week_section
    quick_links_section
  end

  private

  attr_reader :stats

  def toolbar
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        span(style: "color: var(--foreground2);") do
          plain "Welcome back, "
          strong(style: "color: var(--foreground0);") { current_user&.username || "friend" }
        end
      end
      span(class: "toolbar-spacer")
      div(class: "page-actions") do
        a(href: new_letter_path) { button("variant-": "green", "size-": "small") { "+ Letter" } }
        a(href: new_warehouse_order_path) { button("size-": "small") { "+ Order" } }
        a(href: new_letter_batch_path) { button("size-": "small") { "+ Batch" } }
      end
    end
  end

  def section_header(text)
    strong(style: "font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.05ch; color: var(--foreground2);") { text }
  end

  def needs_attention_section
    div(style: "margin-bottom: 1lh;") do
      section_header("Needs Attention")
      div(class: "stat-filters", style: "margin-top: 0.25lh;") do
        if stats[:orders_to_dispatch].to_i > 0
          kpi_chip("To Dispatch", stats[:orders_to_dispatch], warehouse_orders_path(state: "draft"), "yellow")
        end
        kpi_chip("To Print", stats[:letters_to_print], letters_path(status: "pending"), "yellow")
        kpi_chip("To Mail", stats[:letters_to_mail], letters_path(status: "printed"), "yellow")
        kpi_chip("Open Batches", stats[:open_letter_batches], letter_batches_path, "yellow")
      end
    end
  end

  def this_week_section
    div(style: "margin-bottom: 1lh;") do
      section_header("This Week")
      div(class: "stat-filters", style: "margin-top: 0.25lh;") do
        kpi_chip("In Transit", stats[:orders_in_transit], warehouse_orders_path(state: "dispatched"))
        kpi_chip("Shipped", stats[:orders_shipped_this_week], warehouse_orders_path(state: "mailed"))
        kpi_chip("Mailed", stats[:letters_mailed_this_week], letters_path(status: "mailed"))
        kpi_chip("Letters (30d)", stats[:total_letters_this_month], letters_path)
      end
    end
  end

  def kpi_chip(label, value, href, color = nil)
    color_style = color ? "color: var(--#{color});" : ""
    a(href: href, class: "stat-filter") do
      span(class: "stat-count", style: color_style) { format_number(value) }
      span(class: "stat-label") { label }
    end
  end

  def quick_links_section
    wh = policy(::Warehouse::Order.new).index?
    row("gap-": "2", style: "flex-wrap: wrap;") do
      if wh
        warehouse_links = [
          { label: "Orders", href: warehouse_orders_path, icon: "📦", check: -> { true } },
          { label: "Batches", href: warehouse_batches_path, icon: "≡", check: -> { true } },
          { label: "SKUs", href: warehouse_skus_path, icon: "📁", check: -> { policy(::Warehouse::SKU.new).index? } },
          { label: "Purchase Orders", href: warehouse_purchase_orders_path, icon: "📦", check: -> { policy(::Warehouse::PurchaseOrder.new).index? } }
        ]
        column(style: "flex: 1; min-width: 20ch;") { link_panel("Warehouse", warehouse_links) }
      end

      mail_links = [
        { label: "Letters", href: letters_path, icon: "✉", check: -> { policy(::Letter.new).index? } },
        { label: "Batches", href: letter_batches_path, icon: "≡", check: -> { policy(::Letter::Batch.new).index? } },
        { label: "Mail Scanner", href: scanner_letters_path, icon: "↯", check: -> { policy(::Letter.new).index? } },
        { label: "Return Addresses", href: return_addresses_path, icon: "🏠", check: -> { policy(ReturnAddress.new).index? } }
      ]
      column(style: "flex: 1; min-width: 20ch;") { link_panel("Mail", mail_links) }

      column(style: "flex: 1; min-width: 20ch;") do
        div("box-": "round") do
          strong { "Tools" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh;") do
            render_id_lookup_dialog
            if policy(:customs_receipt).index?
              a(href: customs_receipts_path, style: "display: block; padding: 0.25lh 0; text-decoration: none; color: var(--foreground1);") do
                plain "⎘ Customs Receipts"
              end
            end
            a(href: public_root_path, style: "display: block; padding: 0.25lh 0; text-decoration: none; color: var(--foreground1);") do
              plain "🌐 Public Site"
            end
          end
        end
      end
    end
  end

  def link_panel(title, links)
    div("box-": "round") do
      strong { title }
      div("is-": "separator")
      div(style: "margin-top: 0.5lh;") do
        links.each do |link|
          next unless link[:check].call
          a(href: link[:href], style: "display: block; padding: 0.25lh 0; text-decoration: none; color: var(--foreground1);") do
            plain "#{link[:icon]} #{link[:label]}"
          end
        end
      end
    end
  end

  def render_id_lookup_dialog
    dialog(id: "id-lookup-dialog", "size-": "medium", "position-": "center", "container-": "fill") do
      column("box-": "round", "shear-": "top") do
        row("align-": "center between") do
          span("is-": "badge", "variant-": "background0") { "Find object by ID" }
          button("variant-": "foreground0", onclick: safe("this.closest('dialog').close()")) { "×" }
        end
        p(style: "color: var(--foreground2); margin: 0 0 1lh;") { "Enter a Theseus ID or package tracking number..." }
        div("is-": "separator")

        form_with url: helpers.lookup_public_ids_path, method: :post do |f|
          div(style: "padding: 1lh 0;") do
            input(
              type: "text",
              name: :id,
              placeholder: "e.g. ltr!abc123, 9400111...",
              autofocus: true,
              style: "width: 100%;"
            )
          end
          div(style: "display: flex; justify-content: flex-end; padding-top: 0.5lh;") do
            button(type: "submit", "variant-": "green") { "Go!" }
          end
        end
      end
    end

    a(href: "#", onclick: safe("document.getElementById('id-lookup-dialog').showModal(); return false;"), style: "display: block; padding: 0.25lh 0; text-decoration: none; color: var(--foreground1);") do
      plain "⌕ ID Lookup"
    end
  end

  def format_number(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
