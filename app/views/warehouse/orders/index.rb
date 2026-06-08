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
    column("gap-": "2") do
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
    row("align-": "start between") do
      div do
        row("gap-": "1", "align-": "center") do
          h1(style: "margin: 0;") { "Orders" }
          render Components::Shared::Jumpcode.new(path: warehouse_orders_path)
        end
        p(style: "color: var(--foreground2); margin: 0;") do
          plain "#{warehouse_orders.respond_to?(:total_count) ? warehouse_orders.total_count : warehouse_orders.count} orders"
        end
      end
      a(href: new_warehouse_order_path) do
        button("variant-": "green") { "+ New Order" }
      end
    end
  end

  def stats_section
    counts = {
      draft: all_orders.where(aasm_state: :draft).count,
      dispatched: all_orders.where(aasm_state: :dispatched).count,
      mailed: all_orders.where(aasm_state: :mailed).count,
      canceled: all_orders.where(aasm_state: :canceled).count
    }

    row("gap-": "1") do
      stat_pill("Draft", counts[:draft], "background2", "draft")
      stat_pill("At Warehouse", counts[:dispatched], "blue", "dispatched")
      stat_pill("Shipped", counts[:mailed], "green", "mailed")
      stat_pill("Canceled", counts[:canceled], "yellow", "canceled") if counts[:canceled] > 0
    end
  end

  def stat_pill(label, count, variant, filter_state)
    is_active = state == filter_state
    href = if is_active
             warehouse_orders_path(origin: origin, search: search)
           else
             warehouse_orders_path(origin: origin, search: search, state: filter_state)
           end

    a(href: href, style: "text-decoration: none; #{is_active ? 'font-weight: bold;' : ''}") do
      span("is-": "badge", "variant-": variant) { count.to_s }
      plain " #{label}"
    end
  end

  def filters_section
    row("gap-": "1", "align-": "center") do
      form_tag(warehouse_orders_path, method: :get) do
        hidden_field_tag(:origin, origin) if origin.present?
        hidden_field_tag(:state, state) if state.present?
        hidden_field_tag(:user_id, user_id) if user_id.present?
        input(
          type: "text",
          name: "search",
          placeholder: "Search by ID, email, name, or title...",
          value: search,
          style: "width: 30ch;"
        )
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
        a(href: warehouse_orders_path, style: "color: var(--foreground2);") { "× Clear filters" }
      end
    end
  end

  def origin_filter_section
    origins = [
      { key: nil, label: "All" },
      { key: "manual", label: "Manual" },
      { key: "bulk_upload", label: "Bulk upload" },
      { key: "api", label: "API" },
    ]

    row("gap-": "1", "align-": "center") do
      origins.each do |o|
        is_active = origin == o[:key]
        a(
          href: warehouse_orders_path(origin: o[:key], search: search, state: state, user_id: user_id),
          style: "text-decoration: none; #{is_active ? 'font-weight: bold;' : 'color: var(--foreground2);'}"
        ) { o[:label] }
      end
    end
  end

  def orders_list
    if warehouse_orders.any?
      table do
        thead do
          tr do
            th { "Order" }
            th { "Recipient" }
            th(style: "text-align: right;") { "Items" }
            th { "Status" }
          end
        end
        tbody do
          warehouse_orders.each { |o| render_order_row(o) }
        end
      end
    else
      div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
        h2(style: "margin: 0;") { "No orders found" }
        if search.present? || state.present?
          p(style: "color: var(--foreground2);") { "Try adjusting your search or filters." }
        else
          p(style: "color: var(--foreground2);") { "Create your first order to get started." }
          a(href: new_warehouse_order_path) do
            button("variant-": "green") { "+ New Order" }
          end
        end
      end
    end
  end

  def render_order_row(order)
    tr do
      td do
        a(href: warehouse_order_path(order), style: "text-decoration: none; color: var(--foreground0);") do
          strong { order.hc_id }
        end
        if order.user_facing_title.present?
          div(style: "color: var(--foreground2); font-size: 0.85em;") { order.user_facing_title }
        end
        render_tags(order.tags.first(2)) if order.tags.present?
        div(style: "color: var(--foreground2); font-size: 0.85em;") do
          plain order.created_at.strftime("%b %d, %Y")
          plain " · #{order.origin_label}"
          if order.source_tag&.name.present?
            plain " · #{order.source_tag.name}"
          end
        end
      end
      td { plain order.address&.name_line || "—" }
      td(style: "text-align: right;") { plain order.line_items.sum(&:quantity).to_s }
      td { status_label(order) }
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
    form(action: url, method: method == :get ? "get" : "post", &block)
  end

  def hidden_field_tag(name, value)
    input(type: "hidden", name: name, value: value)
  end
end
