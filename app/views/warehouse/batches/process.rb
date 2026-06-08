# frozen_string_literal: true

class Views::Warehouse::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        a(href: warehouse_batch_path(@batch), style: "text-decoration: none; color: var(--foreground2);") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Process Warehouse Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        div("box-": "square", style: "margin-bottom: 1lh;") do
          plain "This will create #{helpers.pluralize(@batch.addresses.count, 'warehouse order')}."
        end

        # Line Items
        div("box-": "round", style: "margin-bottom: 1lh;") do
          strong { "Template: #{@batch.warehouse_template.name}" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh;") do
            @batch.warehouse_template.line_items.each do |line_item|
              div { "#{line_item.quantity}x #{line_item.sku.name}" }
            end
          end
        end

        # Cost Breakdown
        div("box-": "round", style: "margin-bottom: 1lh;") do
          strong { "Cost Breakdown" }
          div("is-": "separator")
          div(class: "detail-grid", style: "margin-top: 0.5lh;") do
            span(class: "detail-label") { "Contents" }
            span { number_to_currency(@batch.contents_cost) }
            span(class: "detail-label") { "Labor" }
            span { number_to_currency(@batch.labor_cost) }
            span(class: "detail-label") { "Postage" }
            span(style: "color: var(--foreground2);") { "TBD" }
            span(class: "detail-label") { "Total (est.)" }
            strong { "~#{number_to_currency(@batch.total_cost)}" }
          end
        end
      end

      div(class: "show-sidebar") do
        div("box-": "round") do
          strong { "Confirm" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh;") do
            form(method: :post, action: process_batch_warehouse_batch_path(@batch)) do
              input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
              button(type: "submit", "variant-": "green", style: "width: 100%;") { "▶ do it!" }
            end
            div(style: "margin-top: 0.5lh;") do
              a(href: warehouse_batch_path(@batch), style: "color: var(--foreground2);") { "Cancel" }
            end
          end
        end
      end
    end
  end
end
