# frozen_string_literal: true

class Views::Warehouse::Orders::Index < Views::Base
  def initialize(warehouse_orders:, all_orders:, origin: nil, search: nil, state: nil, user_id: nil, users: [])
    @warehouse_orders = warehouse_orders
    @all_orders = all_orders
    @origin = origin
    @search = search
    @state = state
    @user_id = user_id
    @users = users
  end

  def view_template
    div(class: "page-container") do
      header_section
      stats_section
      filters_section
      orders_list
      pagination_section
    end
  end

  private

  attr_reader :warehouse_orders, :all_orders, :origin, :search, :state, :user_id, :users

  def header_section
    div(class: "page-header") do
      div do
        div(class: "section-title-group") do
          h1(class: "page-title") { "Orders" }
          render Components::Shared::Jumpcode.new(path: warehouse_orders_path)
        end
        p(class: "page-subtitle") do
          plain "#{warehouse_orders.respond_to?(:total_count) ? warehouse_orders.total_count : warehouse_orders.count} orders"
        end
      end

      a(href: new_warehouse_order_path, "variant-": "green") { "+ New Order" }
    end
  end

  def stats_section
    counts = {
      draft: all_orders.where(aasm_state: :draft).count,
      dispatched: all_orders.where(aasm_state: :dispatched).count,
      mailed: all_orders.where(aasm_state: :mailed).count,
      canceled: all_orders.where(aasm_state: :canceled).count
    }

    div(class: "stat-pill-row") do
      stat_pill("Draft", counts[:draft], :secondary, "draft")
      stat_pill("At Warehouse", counts[:dispatched], :accent, "dispatched")
      stat_pill("Shipped", counts[:mailed], :success, "mailed")
      stat_pill("Canceled", counts[:canceled], :attention, "canceled") if counts[:canceled] > 0
    end
  end

  def stat_pill(label, count, scheme, filter_state)
    is_active = state == filter_state
    href = if is_active
             warehouse_orders_path(origin: origin, search: search)
           else
             warehouse_orders_path(origin: origin, search: search, state: filter_state)
           end

    schemes = {
      secondary: { bg: "var(--bgColor-muted)", border: "var(--borderColor-default)", active_bg: "var(--bgColor-neutral-emphasis)" },
      accent: { bg: "var(--bgColor-accent-muted)", border: "var(--borderColor-accent-muted)", active_bg: "var(--bgColor-accent-emphasis)" },
      success: { bg: "var(--bgColor-success-muted)", border: "var(--borderColor-success-muted)", active_bg: "var(--bgColor-success-emphasis)" },
      attention: { bg: "var(--bgColor-attention-muted)", border: "var(--borderColor-attention-muted)", active_bg: "var(--bgColor-attention-emphasis)" }
    }
    s = schemes[scheme]

    # Conditional styles: active state changes bg/border/color based on runtime state
    a(
      href: href,
      style: "display: flex; align-items: center; gap: 8px; padding: 8px 14px; " \
             "background: #{is_active ? s[:active_bg] : s[:bg]}; " \
             "border: 1px solid #{is_active ? s[:active_bg] : s[:border]}; " \
             "border-radius: 6px; text-decoration: none; " \
             "color: #{is_active ? 'var(--fgColor-onEmphasis)' : 'inherit'}; font-size: 14px;"
    ) do
      span(class: "fw-semibold") { count.to_s }
      span(class: is_active ? "" : "kv-label") { label }
    end
  end

  def filters_section
    div(class: "filter-bar-wrap") do
      div(class: "filter-search") do
        form_tag(warehouse_orders_path, method: :get) do
          hidden_field_tag(:origin, origin) if origin.present?
          hidden_field_tag(:state, state) if state.present?
          hidden_field_tag(:user_id, user_id) if user_id.present?
          input(
            type: "text",
            name: "search",
            placeholder: "Search by ID, email, name, or title...",
            value: search,
            style: "width: 100%;"
          )
        end
      end

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { warehouse_orders_path(origin: origin, search: search, state: state, user_id: uid) }
        )
      end

      origin_filter_section

      has_filters = search.present? || state.present? || user_id.present? || origin.present?
      if has_filters
        a(
          href: warehouse_orders_path,
          style: "font-size: smaller;"
        ) { "× Clear filters" }
    end
  end

  def origin_filter_section
    origins = [
      { key: nil, label: "All", icon: :rows },
      { key: "manual", label: "Manual", icon: :pencil },
      { key: "bulk_upload", label: "Bulk upload", icon: :upload },
      { key: "api", label: "API", icon: :code },
    ]

    div(class: "origin-filter") do
      origins.each do |o|
        is_active = origin == o[:key]
        a_style = is_active ? "font-weight: bold;" : ""
        a(
          href: warehouse_orders_path(origin: o[:key], search: search, state: state, user_id: user_id),
          style: a_style
        ) { o[:label] }
      end
    end
  end

  def orders_list
    if warehouse_orders.any?
      div("box-": "round") do
        div(style: "padding: 1lh 1ch; border-bottom: 1px solid var(--foreground2);") do
          div(class: "order-header-row") do
            span(class: "fw-semibold") { "Order" }
            div(class: "order-header-side") do
              span(class: "order-header-col order-header-col--recipient") { "Recipient" }
              span(class: "order-header-col order-header-col--items") { "Items" }
              span(class: "order-header-col order-header-col--status") { "Status" }
            end
          end
        end

        warehouse_orders.each do |order|
          div(style: "padding: 1lh 1ch; border-bottom: 1px solid var(--background3);") do
            render_order_row(order)
          end
        end
      end
    else
      div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
        h2(style: "margin: 0;") { "📦 No orders found" }
        if search.present? || state.present?
          p(style: "color: var(--foreground2);") { "Try adjusting your search or filters." }
        else
          p(style: "color: var(--foreground2);") { "Create your first order to get started." }
          a(href: new_warehouse_order_path, "variant-": "green") { "+ New Order" }
        end
      end
  end

  def render_order_row(order)
    a(href: warehouse_order_path(order), class: "order-link") do
      div(class: "order-info") do
        div(class: "order-id-row") do
          span(class: "order-hc-id") { order.hc_id }
          if order.user_facing_title.present?
            span(class: "dot-sep") { "·" }
            span(class: "order-title") { order.user_facing_title }
          end
          render_tags(order.tags.first(2)) if order.tags.present?
        end
        div(class: "order-meta") do
          plain order.created_at.strftime("%b %d, %Y")
          plain " · #{order.origin_label}"
          if order.source_tag&.name.present?
            plain " · #{order.source_tag.name}"
          end
        end
      end

      div(class: "order-side") do
        div(class: "order-recipient") do
          div(class: "order-recipient-name") { order.address&.name_line || "—" }
          div(class: "order-recipient-email") { order.recipient_email }
        end

        div(class: "order-items-col", title: order.line_items.map { |li| "#{li.quantity}× #{li.sku.name}" }.join(", ")) do
          span(class: "fw-semibold") { order.line_items.sum(&:quantity).to_s }
          span(class: "resource-card-meta resource-card-meta--inline") { "items" }
        end

        div(class: "order-status-col") do
          status_label(order)
        end
      end
    end
  end

  def render_tags(tags)
    tags.compact_blank.each do |tag|
      span("is-": "badge", "variant-": "background2") { tag }
    end
  end

  def status_label(order)
    variant = case order.aasm_state.to_sym
              when :draft then "background2"
              when :dispatched then "blue"
              when :mailed then "green"
              when :errored then "red"
              when :canceled then "yellow"
              else "background2"
              end

    span("is-": "badge", "variant-": variant) { order.humanized_state }
  end

  def pagination_section
    render Components::Shared::Pagination.new(
      collection: warehouse_orders,
      base_path: method(:warehouse_orders_path),
      filter_params: { origin: origin, search: search, state: state, user_id: user_id }
    )
  end

  def form_tag(url, method:, &block)
    form(action: url, method: method == :get ? "get" : "post", class: "form-contents", &block)
  end

  def hidden_field_tag(name, value)
    input(type: "hidden", name: name, value: value)
  end
end
