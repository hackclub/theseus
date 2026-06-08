# frozen_string_literal: true

class Views::Warehouse::Batches::Show < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    # Header toolbar
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        a(href: warehouse_batches_path, style: "text-decoration: none; color: var(--foreground2);") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "Warehouse Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      row("gap-": "1", "align-": "center") do
        span(style: "color: var(--foreground2);") { "#{helpers.pluralize(@batch.addresses.count, 'address')}" }
        if @batch.tags.any?
          render Components::Shared::Tags.new(tags: @batch.tags)
        end
      end
      span(class: "toolbar-spacer")
      row("gap-": "1", "align-": "center") do
        a(href: edit_warehouse_batch_path(@batch), "size-": "small") { "✎ Edit" }
        if @batch.fields_mapped?
          a(href: process_confirm_warehouse_batch_path(@batch), "variant-": "green", "size-": "small") { "▶ Process" }
        end
        form(method: :post, action: warehouse_batch_path(@batch)) do
          input(type: :hidden, name: :_method, value: :delete)
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          button(type: "submit", "variant-": "red", "size-": "small", data: { turbo_confirm: "Delete this batch?" }) { "✕" }
        end
      end
    end

    div(class: "show-layout") do
      # Main content
      div(class: "show-main") do
        batch_details
        orders_section if @batch.orders.any?
        addresses_section if @batch.addresses.any?
      end

      # Sidebar
      div(class: "show-sidebar") do
        div("box-": "round", style: "margin-bottom: 1lh;") do
          strong { "Actions" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh;") do
            if @batch.fields_mapped?
              a(href: process_confirm_warehouse_batch_path(@batch), "variant-": "green", style: "width: 100%; display: block; text-align: center;") { "▶ Process Batch" }
            else
              span(style: "color: var(--foreground2);") { "Map fields before processing" }
            end
          end
        end

        if @batch.processed?
          div("box-": "round") do
            strong { "Cost Summary" }
            div("is-": "separator")
            div(class: "detail-grid", style: "margin-top: 0.5lh;") do
              span(class: "detail-label") { "Contents" }
              span { number_to_currency(@batch.contents_cost) }
              span(class: "detail-label") { "Labor" }
              span { number_to_currency(@batch.labor_cost) }
              span(class: "detail-label") { "Total" }
              strong { number_to_currency(@batch.total_cost) }
            end
          end
        end
      end
    end
  end

  private

  def batch_details
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Details" }
      div("is-": "separator")
      div(class: "detail-grid", style: "margin-top: 0.5lh;") do
        span(class: "detail-label") { "Status" }
        span { render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch) }
        span(class: "detail-label") { "Template" }
        span { @batch.warehouse_template&.name || "—" }
        span(class: "detail-label") { "Title" }
        span { @batch.warehouse_user_facing_title || "—" }
        span(class: "detail-label") { "Created" }
        span { "#{time_ago_in_words(@batch.created_at)} ago" }
      end
    end
  end

  def orders_section
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Orders (#{@batch.orders.count})" }
      div("is-": "separator")
      table(class: "data-table") do
        thead do
          tr do
            %w[ID Recipient Status].each { |h| th { h } }
          end
        end
        tbody do
          @batch.orders.includes(:address).limit(100).each do |order|
            tr do
              td { a(href: warehouse_order_path(order)) { order.public_id } }
              td { plain "#{order.address&.first_name} #{order.address&.last_name}" }
              td { render Components::Shared::StatusBadge.new(status: order.aasm_state, type: :warehouse_order) }
            end
          end
        end
      end
    end
  end

  def addresses_section
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Addresses (#{@batch.addresses.count})" }
      div("is-": "separator")
      table(class: "data-table") do
        thead do
          tr do
            %w[Name Address City State ZIP Country].each { |h| th { h } }
          end
        end
        tbody do
          @batch.addresses.limit(100).each do |addr|
            tr do
              td { "#{addr.first_name} #{addr.last_name}" }
              td { addr.line_1 || "—" }
              td { addr.city || "—" }
              td { addr.state || "—" }
              td { addr.postal_code || "—" }
              td { addr.country || "—" }
            end
          end
        end
      end
    end
  end
end
