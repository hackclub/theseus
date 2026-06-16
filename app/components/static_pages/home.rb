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
    div(class: "toolbar") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        span(class: "text-muted") do
          plain "Welcome back, "
          strong { current_user&.username || "friend" }
        end
      end
      span(class: "spacer")
      div(class: "page-actions") do
        a(href: new_letter_path) { button(class: "btn-success btn-sm") { "+ Letter" } }
        a(href: new_warehouse_order_path) { button(class: "btn-sm") { "+ Order" } }
        a(href: new_letter_batch_path) { button(class: "btn-sm") { "+ Batch" } }
      end
    end
  end

  def section_header(text)
    strong(style: "font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.025rem; color: GrayText;") { text }
  end

  def needs_attention_section
    div(style: "margin-bottom: 1rem;") do
      section_header("Needs Attention")
      div(class: "stat-filters", style: "margin-top: 0.25rem;") do
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
    div(style: "margin-bottom: 1rem;") do
      section_header("This Week")
      div(class: "stat-filters", style: "margin-top: 0.25rem;") do
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
    div(style: "display:flex;gap:2rem;flex-wrap:wrap;margin-top:1rem") do
      if wh
        warehouse_links = [
          { label: "Orders", href: warehouse_orders_path, icon: "📦", check: -> { true } },
          { label: "Batches", href: warehouse_batches_path, icon: "≡", check: -> { true } },
          { label: "SKUs", href: warehouse_skus_path, icon: "📁", check: -> { policy(::Warehouse::SKU.new).index? } },
          { label: "Purchase Orders", href: warehouse_purchase_orders_path, icon: "📦", check: -> { policy(::Warehouse::PurchaseOrder.new).index? } }
        ]
        div(style: "min-width:10rem") { link_panel("Warehouse", warehouse_links) }
      end

      mail_links = [
        { label: "Letters", href: letters_path, icon: "✉", check: -> { policy(::Letter.new).index? } },
        { label: "Batches", href: letter_batches_path, icon: "≡", check: -> { policy(::Letter::Batch.new).index? } },
        { label: "Mail Scanner", href: scanner_letters_path, icon: "↯", check: -> { policy(::Letter.new).index? } },
        { label: "Return Addresses", href: return_addresses_path, icon: "🏠", check: -> { policy(ReturnAddress.new).index? } }
      ]
      div(style: "min-width:10rem") { link_panel("Mail", mail_links) }

      tools_links = [
        { label: "ID Lookup", href: public_ids_path, icon: "⌕", check: -> { true } },
        *(policy(:customs_receipt).index? ? [{ label: "Customs Receipts", href: customs_receipts_path, icon: "⎘", check: -> { true } }] : []),
        { label: "Public Site", href: public_root_path, icon: "🌐", check: -> { true } }
      ]
      div(style: "min-width:10rem") { link_panel("Tools", tools_links) }
    end
  end

  def link_panel(title, links)
    h3(style: "margin:0 0 0.25rem") { title }
    ul(style: "list-style:none;padding:0;margin:0") do
      links.each do |link|
        next unless link[:check].call
        li do
          a(href: link[:href]) { "#{link[:icon]} #{link[:label]}" }
        end
      end
    end
  end

  def render_id_lookup_dialog
  end

  def format_number(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
