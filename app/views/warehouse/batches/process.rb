# frozen_string_literal: true

class Views::Warehouse::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-container--narrow") do
      div(class: "page-title-group mb-3") do
      a(href: warehouse_batch_path(@batch), "size-": "small") { "← Back to batch" }
        h1(class: "page-title") { "Process Warehouse Batch ##{@batch.id}" }
      end

      div("box-": "square", style: "margin-bottom: 2lh;") do
        plain "This will create #{helpers.pluralize(@batch.addresses.count, 'warehouse order')}."
      end

      # Line Items
      div("box-": "round", style: "margin-bottom: 2lh;") do
        h3(style: "margin: 0;") { "Template: #{@batch.warehouse_template.name}" }
        div("is-": "separator")
        @batch.warehouse_template.line_items.each do |line_item|
          div(class: "kv-row") do
            span { "#{line_item.quantity}x #{line_item.sku.name}" }
          end
        end
      end

      # Cost Breakdown
      div("box-": "round", style: "margin-bottom: 2lh;") do
        h3(style: "margin: 0;") { "Cost Breakdown" }
        div("is-": "separator")
        dl(class: "detail-dl") do
          dt { "Contents" }
          dd { number_to_currency(@batch.contents_cost) }

          dt { "Labor" }
          dd { number_to_currency(@batch.labor_cost) }

          dt { "Postage" }
          dd(class: "kv-label") { "TBD" }

          dt(class: "fw-semibold") { "Total (est.)" }
          dd(class: "fw-semibold") { "~#{number_to_currency(@batch.total_cost)}" }
        end
      end

      # Submit
      div(class: "page-actions") do
        a(href: warehouse_batch_path(@batch)) { "Cancel" }
        form(method: :post, action: process_batch_warehouse_batch_path(@batch), class: "form-inline") do
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          button(type: "submit", "variant-": "green") { "▶ do it!" }
        end
      end
    end
  end
end
