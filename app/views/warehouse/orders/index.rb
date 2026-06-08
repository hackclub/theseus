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
    toolbar
    stat_filters
    orders_list
    pagination_section
  end

  private

  attr_reader :warehouse_orders, :all_orders, :origin, :search, :state, :user_id, :users

  def toolbar
    render Components::Shared::PageToolbar.new(
      title: "Orders",
      jumpcode_path: warehouse_orders_path,
      search_path: warehouse_orders_path,
      search_value: search,
      search_placeholder: "Search orders...",
      search_params: { state: state, origin: origin, user_id: user_id },
      action_href: new_warehouse_order_path,
      action_label: "+ New Order"
    ) do
      render Components::Shared::OriginTabs.new(
        options: { nil => "All", "manual" => "Manual", "bulk_upload" => "Bulk", "api" => "API" },
        active: origin,
        base_path: ->(params = {}) { warehouse_orders_path(search: search, state: state, user_id: user_id, **params) },
        preserved_params: { search: search, state: state, user_id: user_id }
      )

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { warehouse_orders_path(origin: origin, search: search, state: state, user_id: uid) }
        )
      end

      if search.present? || state.present? || origin.present? || user_id.present?
        a(href: warehouse_orders_path, class: "stat-filter") { "× Clear" }
      end
    end
  end

  def stat_filters
    counts = {
      draft: all_orders.where(aasm_state: :draft).count,
      dispatched: all_orders.where(aasm_state: :dispatched).count,
      mailed: all_orders.where(aasm_state: :mailed).count,
      canceled: all_orders.where(aasm_state: :canceled).count
    }

    render Components::Shared::StatFilters.new(
      stats: [
        { label: "Draft", count: counts[:draft], color: "yellow", param: "draft" },
        { label: "At Warehouse", count: counts[:dispatched], color: "blue", param: "dispatched" },
        { label: "Shipped", count: counts[:mailed], color: "green", param: "mailed" },
        { label: "Canceled", count: counts[:canceled], param: "canceled" },
      ],
      active: state,
      filter_key: :state,
      base_path: ->(params = {}) { warehouse_orders_path(origin: origin, search: search, user_id: user_id, **params) },
      preserved_params: { origin: origin, search: search, user_id: user_id },
      total: warehouse_orders.respond_to?(:total_count) ? warehouse_orders.total_count : warehouse_orders.count
    )
  end

  def orders_list
    if warehouse_orders.any?
      table do
        thead do
          tr do
            th { "ID" }
            th { "Date" }
            th { "Recipient" }
            th(style: "text-align: right;") { "Items" }
            th { "Status" }
          end
        end
        tbody do
          warehouse_orders.each do |order|
            tr do
              td do
                a(href: warehouse_order_path(order), style: "text-decoration: none; color: var(--foreground0);") { order.hc_id }
              end
              td(style: "color: var(--foreground2);") { plain order.created_at.strftime("%b %d") }
              td { plain order.address&.name_line || "—" }
              td(style: "text-align: right;") { plain order.line_items.sum(&:quantity).to_s }
              td { status_badge(order) }
            end
          end
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

  def status_badge(order)
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
end
