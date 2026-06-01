# frozen_string_literal: true

class Components::StaticPages::Home < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(stats:)
    @stats = stats
  end

  def view_template
    div(class: "page-container") do
      header_section
      kpi_section
      main_section
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
        render Primer::Beta::Button.new(tag: :a, href: new_letter_path, scheme: :primary) do |btn|
          btn.with_leading_visual_icon(icon: :mail)
          "Send a letter"
        end
        render Primer::Beta::Button.new(tag: :a, href: new_warehouse_order_path, scheme: :secondary) do |btn|
          btn.with_leading_visual_icon(icon: :package)
          "Send a warehouse order"
        end
        render Primer::Beta::Button.new(tag: :a, href: new_letter_batch_path, scheme: :secondary) do |btn|
          btn.with_leading_visual_icon(icon: :stack)
          "Create a batch"
        end
      end
    end
  end

  def kpi_section
    div(class: "content-section-lg") do
      # Action items section
      h2(class: "home-kpi-heading") { "Needs attention" }
      div(class: "home-kpi-grid mb-3") do
        action_card("Orders to dispatch", stats[:orders_to_dispatch], :package, warehouse_orders_path(state: "draft"))
        action_card("Letters to print", stats[:letters_to_print], :mail, letters_path(status: "pending"))
        action_card("Ready to mail", stats[:letters_to_mail], :check, letters_path(status: "printed"))
        action_card("Open batches", stats[:open_letter_batches], :inbox, letter_batches_path)
        action_card("My queued letters", stats[:my_queued_letters], :inbox, letter_queues_path) if stats[:my_queue_count].to_i > 0
      end

      # Global stats section
      h2(class: "home-kpi-heading") { "This week" }
      div(class: "home-kpi-grid") do
        stat_card("In transit", stats[:orders_in_transit], :rocket, warehouse_orders_path(state: "dispatched"))
        stat_card("Orders shipped", stats[:orders_shipped_this_week], :package, warehouse_orders_path(state: "mailed"))
        stat_card("Letters mailed", stats[:letters_mailed_this_week], :"paper-airplane", letters_path(status: "mailed"))
        stat_card("Letters (30d)", stats[:total_letters_this_month], :graph, letters_path)
      end
    end
  end

  def main_section
    wh = policy(::Warehouse::Order.new).index?
    div(class: "home-main-grid") do
      if wh
        warehouse_links = [
          { label: "Orders", href: warehouse_orders_path, icon: :package, check: -> { true } },
          { label: "Batches", href: warehouse_batches_path, icon: :stack, check: -> { true } },
          { label: "SKUs", href: warehouse_skus_path, icon: :archive, check: -> { policy(::Warehouse::SKU.new).index? } },
          { label: "Purchase Orders", href: warehouse_purchase_orders_path, icon: :container, check: -> { policy(::Warehouse::PurchaseOrder.new).index? } }
        ]
        link_panel("Warehouse", warehouse_links)
      end

      mail_links = [
        { label: "Letters", href: letters_path, icon: :mail, check: -> { policy(::Letter.new).index? } },
        { label: "Batches", href: letter_batches_path, icon: :stack, check: -> { policy(::Letter::Batch.new).index? } },
        { label: "Mail Scanner", href: scanner_letters_path, icon: :zap, check: -> { policy(::Letter.new).index? } },
        { label: "Return Addresses", href: return_addresses_path, icon: :home, check: -> { policy(ReturnAddress.new).index? } }
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
            span(class: "link-panel-icon") do
              render Primer::Beta::Octicon.new(icon: :"file-badge", size: :small)
            end
            span(class: "link-panel-label") { "Customs Receipts" }
          end if policy(:customs_receipt).index?
          a(
            href: public_root_path,
            class: "link-panel-item"
          ) do
            span(class: "link-panel-icon") do
              render Primer::Beta::Octicon.new(icon: :globe, size: :small)
            end
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
        span(class: has_items ? "text-attention" : "link-panel-icon") do
          render Primer::Beta::Octicon.new(icon:, size: :small)
        end
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
        span(class: "link-panel-icon") do
          render Primer::Beta::Octicon.new(icon:, size: :small)
        end
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
            span(class: "link-panel-icon") do
              render Primer::Beta::Octicon.new(icon: link[:icon], size: :small)
            end
            span(class: "link-panel-label") { link[:label] }
          end
        end
      end
    end
  end

  def render_id_lookup_dialog
    span(class: "link-panel-icon") do
      render Primer::Beta::Octicon.new(icon: :search, size: :small)
    end
    render(Primer::Alpha::Dialog.new(
      title: "Find object by ID",
      subtitle: "Enter a Theseus ID or package tracking number...",
      size: :medium
    )) do |dialog|
      dialog.with_show_button(scheme: :invisible, classes: "Link--primary") do
        plain "ID Lookup"
      end
      dialog.with_body do
        form_with url: helpers.lookup_public_ids_path, method: :post do |f|
          render(Primer::Alpha::TextField.new(
            name: :id,
            label: nil,
            placeholder: "e.g. ltr!abc123, 9400111...",
            full_width: true,
            autofocus: true
          ))
          div(class: "dialog-form-footer") do
            render(Primer::ButtonComponent.new(type: :submit, scheme: :primary)) { "Go!" }
          end
        end
      end
    end
  end
end
