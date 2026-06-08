# frozen_string_literal: true

class Components::StaticPages::Home < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(stats:)
    @stats = stats
  end

  def view_template
    div(class: "home-page") do
      div(class: "page-container") do
        header_section
        kpi_section
        main_section
      end
    end
  end

  private

  attr_reader :stats

  def header_section
    header(class: "home-header") do
      div do
        h1(class: "home-title") { "Theseus" }
        p(class: "home-welcome") do
          plain "Welcome back, "
          strong { current_user&.username || "friend" }
        end
      end

      div(class: "page-actions") do
        a(href: new_letter_path) do
          button("variant-": "green") { "✉ Send a letter" }
        end
        a(href: new_warehouse_order_path) do
          button { "📦 Send a warehouse order" }
        end
        a(href: new_letter_batch_path) do
          button { "≡ Create a batch" }
        end
      end
    end
  end

  def kpi_section
    div(class: "content-section-lg") do
      # Action items section
      h2(class: "home-section-heading") { "Needs Attention" }
      div(class: "home-kpi-grid mb-3") do
        action_card("Orders to dispatch", stats[:orders_to_dispatch], "📦", warehouse_orders_path(state: "draft"))
        action_card("Letters to print", stats[:letters_to_print], "✉", letters_path(status: "pending"))
        action_card("Ready to mail", stats[:letters_to_mail], "✓", letters_path(status: "printed"))
        action_card("Open batches", stats[:open_letter_batches], "📥", letter_batches_path)
        action_card("My queued letters", stats[:my_queued_letters], "📥", letter_queues_path) if stats[:my_queue_count].to_i > 0
      end

      # Global stats section
      h2(class: "home-section-heading") { "This Week" }
      div(class: "home-kpi-grid") do
        stat_card("In transit", stats[:orders_in_transit], "🚀", warehouse_orders_path(state: "dispatched"))
        stat_card("Orders shipped", stats[:orders_shipped_this_week], "📦", warehouse_orders_path(state: "mailed"))
        stat_card("Letters mailed", stats[:letters_mailed_this_week], "✈", letters_path(status: "mailed"))
        stat_card("Letters (30d)", stats[:total_letters_this_month], "📊", letters_path)
      end
    end
  end

  def main_section
    wh = policy(::Warehouse::Order.new).index?
    div(class: "home-main-grid") do
      if wh
        warehouse_links = [
          { label: "Orders", href: warehouse_orders_path, icon: "📦", check: -> { true } },
          { label: "Batches", href: warehouse_batches_path, icon: "≡", check: -> { true } },
          { label: "SKUs", href: warehouse_skus_path, icon: "📁", check: -> { policy(::Warehouse::SKU.new).index? } },
          { label: "Purchase Orders", href: warehouse_purchase_orders_path, icon: "📦", check: -> { policy(::Warehouse::PurchaseOrder.new).index? } }
        ]
        link_panel("Warehouse", warehouse_links)
      end

      mail_links = [
        { label: "Letters", href: letters_path, icon: "✉", check: -> { policy(::Letter.new).index? } },
        { label: "Batches", href: letter_batches_path, icon: "≡", check: -> { policy(::Letter::Batch.new).index? } },
        { label: "Mail Scanner", href: scanner_letters_path, icon: "↯", check: -> { policy(::Letter.new).index? } },
        { label: "Return Addresses", href: return_addresses_path, icon: "🏠", check: -> { policy(ReturnAddress.new).index? } }
      ]
      link_panel("Mail", mail_links)

      div(class: "link-panel") do
        div(class: "link-panel-header") do
          h3(class: "link-panel-title") { "Tools" }
        end
        div(class: "link-panel-body") do
          div(class: "link-panel-item") do
            render_id_lookup_dialog
          end
          a(
            href: customs_receipts_path,
            class: "link-panel-item"
          ) do
            span(class: "link-panel-icon") { "⎘" }
            span(class: "link-panel-label") { "Customs Receipts" }
          end if policy(:customs_receipt).index?
          a(
            href: public_root_path,
            class: "link-panel-item"
          ) do
            span(class: "link-panel-icon") { "🌐" }
            span(class: "link-panel-label") { "Public Site" }
          end
        end
      end
    end
  end

  def action_card(title, value, icon, href)
    has_items = value.to_i > 0

    a(
      href:,
      class: "dash-card#{has_items ? ' dash-card--attention' : ''}"
    ) do
      div(class: "dash-card-inner") do
        div do
          p(class: "dash-card-label") { title }
          span(class: "dash-card-value") { value.to_s }
        end
        span(class: has_items ? "text-attention" : "link-panel-icon") { icon }
      end
    end
  end

  def stat_card(title, value, icon, href)
    a(
      href:,
      class: "dash-card"
    ) do
      div(class: "dash-card-inner") do
        div do
          p(class: "dash-card-label") { title }
          span(class: "dash-card-value") { value.to_s }
        end
        span(class: "link-panel-icon") { icon }
      end
    end
  end

  def link_panel(title, links)
    div(class: "link-panel") do
      div(class: "link-panel-header") do
        h3(class: "link-panel-title") { title }
      end
      div(class: "link-panel-body") do
        links.each do |link|
          next unless link[:check].call
          a(
            href: link[:href],
            class: "link-panel-item"
          ) do
            span(class: "link-panel-icon") { link[:icon] }
            span(class: "link-panel-label") { link[:label] }
          end
        end
      end
    end
  end

  def render_id_lookup_dialog
    span(class: "link-panel-icon") { "⌕" }

    dialog(id: "id-lookup-dialog", "size-": "medium", "position-": "center", "container-": "fill") do
      column( "box-": "round", "shear-": "top") do
        row( "align-": "center between") do
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
          div(class: "dialog-form-footer") do
            button(type: "submit", "variant-": "green") { "Go!" }
          end
        end
      end
    end

    a(href: "#", onclick: safe("document.getElementById('id-lookup-dialog').showModal(); return false;"), class: "Link--primary") { "ID Lookup" }
  end
end
