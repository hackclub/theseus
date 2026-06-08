# frozen_string_literal: true

class Components::StaticPages::Home < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(stats:)
    @stats = stats
  end

  def view_template
    column("gap-": "1", style: "padding: 1lh 2ch;") do
      header_section
      kpi_section
      main_section
    end
  end

  private

  attr_reader :stats

  def header_section
    row("align-": "start between", style: "margin-bottom: 1lh;") do
      column do
        h1(style: "margin: 0;") { "Theseus" }
        p(style: "color: var(--foreground2); margin: 0;") do
          plain "Welcome back, "
          strong { current_user&.username || "friend" }
        end
      end
      row("gap-": "1", "align-": "center") do
        a(href: new_letter_path) { button("size-": "small", "variant-": "green") { "+ Letter" } }
        a(href: new_warehouse_order_path) { button("size-": "small") { "+ Order" } }
        a(href: new_letter_batch_path) { button("size-": "small") { "+ Batch" } }
      end
    end
  end

  def kpi_section
    h3(style: "color: var(--foreground2); margin: 0 0 0.5lh;") { "Needs Attention" }
    row("gap-": "2", style: "margin-bottom: 1lh; flex-wrap: wrap;") do
      stats[:orders_to_dispatch].to_i > 0 && kpi_item("Orders to dispatch", stats[:orders_to_dispatch], warehouse_orders_path(state: "draft"), "yellow")
      kpi_item("To print", stats[:letters_to_print], letters_path(status: "pending"), "yellow")
      kpi_item("To mail", stats[:letters_to_mail], letters_path(status: "printed"))
      kpi_item("Open batches", stats[:open_letter_batches], letter_batches_path)
    end

    h3(style: "color: var(--foreground2); margin: 0 0 0.5lh;") { "This Week" }
    row("gap-": "2", style: "margin-bottom: 1lh; flex-wrap: wrap;") do
      kpi_item("In transit", stats[:orders_in_transit], warehouse_orders_path(state: "dispatched"))
      kpi_item("Shipped", stats[:orders_shipped_this_week], warehouse_orders_path(state: "mailed"))
      kpi_item("Mailed", stats[:letters_mailed_this_week], letters_path(status: "mailed"))
      kpi_item("Letters (30d)", stats[:total_letters_this_month], letters_path)
    end
  end

  def kpi_item(label, value, href, variant = nil)
    a(href: href, style: "text-decoration: none; color: var(--foreground0);") do
      column do
        span(style: "font-size: 1.5em; font-weight: bold;#{ variant == "yellow" ? " color: var(--yellow);" : ""}") { value.to_s }
        span(style: "color: var(--foreground2); font-size: 0.85em;") { label }
      end
    end
  end

  def main_section
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
          strong(style: "display: block; padding: 0.5lh 1ch; border-bottom: 1px solid var(--background2);") { "Tools" }
          div(style: "padding: 0.25lh 1ch;") do
            render_id_lookup_dialog
          end
          if policy(:customs_receipt).index?
            a(href: customs_receipts_path, style: "display: block; padding: 0.25lh 1ch; text-decoration: none; color: var(--foreground1);") do
              plain "⎘ Customs Receipts"
            end
          end
          a(href: public_root_path, style: "display: block; padding: 0.25lh 1ch; text-decoration: none; color: var(--foreground1);") do
            plain "🌐 Public Site"
          end
        end
      end
    end
  end

  def link_panel(title, links)
    div("box-": "round") do
      strong(style: "display: block; padding: 0.5lh 1ch; border-bottom: 1px solid var(--background2);") { title }
      links.each do |link|
        next unless link[:check].call
        a(href: link[:href], style: "display: block; padding: 0.25lh 1ch; text-decoration: none; color: var(--foreground1);") do
          plain "#{link[:icon]} #{link[:label]}"
        end
      end
    end
  end

  def render_id_lookup_dialog
    span(style: "margin-right: 0.5ch;") { "⌕" }

    dialog(id: "id-lookup-dialog", "size-": "medium", "position-": "center", "container-": "fill") do
      column("box-": "round", "shear-": "top") do
        row("align-": "center between") do
          span("is-": "badge", "variant-": "background0") { "Find object by ID" }
          button("size-": "small", "variant-": "foreground0", onclick: safe("this.closest('dialog').close()")) { "×" }
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

    a(href: "#", onclick: safe("document.getElementById('id-lookup-dialog').showModal(); return false;"), style: "color: var(--foreground1); text-decoration: none;") { "ID Lookup" }
  end
end
