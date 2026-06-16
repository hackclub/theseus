# frozen_string_literal: true

class Views::Warehouse::Batches::Show < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: warehouse_batches_path, style: "text-decoration: none; color: GrayText;") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "Warehouse Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        span(style: "color: GrayText;") { "#{helpers.pluralize(@batch.addresses.count, 'address')}" }
        if @batch.tags.any?
          render Components::Shared::Tags.new(tags: @batch.tags)
        end
      end
      span(class: "spacer")
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: edit_warehouse_batch_path(@batch)) { "✎ Edit" }
        if @batch.fields_mapped?
          a(href: process_confirm_warehouse_batch_path(@batch)) do
            button(class: "btn-success btn-sm") { "▶ Process" }
          end
        end
        form(method: :post, action: warehouse_batch_path(@batch)) do
          input(type: :hidden, name: :_method, value: :delete)
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          button(type: "submit", class: "btn-danger btn-sm", data: { turbo_confirm: "Delete this batch?" }) { "✕" }
        end
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        batch_details
        orders_section if @batch.orders.any?
        addresses_section if @batch.addresses.any?
      end

      div(class: "show-sidebar") do
        actions_box
        cost_summary_box if @batch.processed?
      end
    end
  end

  private

  def batch_details
    section(style: "margin-bottom: 1rem;") do
      strong { "Details" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "Template" }
        span { @batch.warehouse_template&.name || "—" }
        span(class: "detail-label") { "Title" }
        span { @batch.warehouse_user_facing_title || "—" }
        span(class: "detail-label") { "Created" }
        span { @batch.created_at.strftime("%b %d, %Y %H:%M") }
        span(class: "detail-label") { "Addresses" }
        span { @batch.addresses.count.to_s }
        span(class: "detail-label") { "Orders" }
        span { @batch.orders.count.to_s }
      end
    end
  end

  def orders_section
    section(style: "margin-bottom: 1rem;") do
      strong { "Orders (#{@batch.orders.count})" }
      hr
      table(style: "margin-top: 0.5rem; width: 100%;") do
        thead do
          tr do
            th(style: "text-align: left;") { "ID" }
            th(style: "text-align: left;") { "Recipient" }
            th(style: "text-align: left;") { "Status" }
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
    section(style: "margin-bottom: 1rem;") do
      strong { "Addresses (#{@batch.addresses.count})" }
      hr
      table(style: "margin-top: 0.5rem; width: 100%;") do
        thead do
          tr do
            th(style: "text-align: left;") { "Name" }
            th(style: "text-align: left;") { "City" }
            th(style: "text-align: left;") { "State" }
            th(style: "text-align: left;") { "Country" }
          end
        end
        tbody do
          @batch.addresses.limit(100).each do |addr|
            tr do
              td { "#{addr.first_name} #{addr.last_name}" }
              td { addr.city || "—" }
              td { addr.state || "—" }
              td { addr.country || "—" }
            end
          end
        end
      end
    end
  end

  def actions_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Actions" }
      hr
      div(style: "margin-top: 0.5rem;") do
        if @batch.fields_mapped?
          a(href: process_confirm_warehouse_batch_path(@batch)) do
            button(class: "btn-success", style: "width: 100%;") { "▶ Process Batch" }
          end
        elsif @batch.processed?
          div(style: "text-align: center; padding: 1rem 0; color: var(--green);") do
            span(style: "font-size: 2em;") { "✓" }
            div(style: "margin-top: 0.5rem;") { strong { "Processed" } }
          end
        else
          span(style: "color: GrayText;") { "Map fields before processing" }
        end
      end
    end
  end

  def cost_summary_box
    section do
      strong { "Cost Summary" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
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
