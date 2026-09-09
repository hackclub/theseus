# frozen_string_literal: true

class Views::Warehouse::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(class: "flex-row") do
        a(href: warehouse_batch_path(@batch), style: "text-decoration: none; color: var(--foreground2);") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Process Warehouse Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        div(class: "banner mb-1") do
          plain "This will create #{helpers.pluralize(@batch.addresses.count, 'warehouse order')}."
        end

        section(class: "mb-1") do
          strong { "Template: #{@batch.warehouse_template.name}" }
          hr
          div(class: "mt-half") do
            @batch.warehouse_template.line_items.each do |line_item|
              div { "#{line_item.quantity}× #{line_item.sku.name}" }
            end
          end
        end

        section(class: "mb-1") do
          strong { "Cost Breakdown" }
          hr
          div(class: "detail-grid mt-half") do
            span(class: "detail-label") { "Contents" }
            span { number_to_currency(@batch.contents_cost) }
            span(class: "detail-label") { "Labor" }
            span { number_to_currency(@batch.labor_cost) }
            span(class: "detail-label") { "Postage" }
            span(class: "text-muted") { "TBD" }
          end
          hr(style: "margin:0.5rem 0")
          div(class: "detail-grid") do
            span(class: "detail-label") { "Total (est.)" }
            strong { "~#{number_to_currency(@batch.total_cost)}" }
          end
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "Confirm" }
          hr
          div(class: "mt-half") do
            form(method: :post, action: process_batch_warehouse_batch_path(@batch)) do
              input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
              button(type: "submit", class: "btn-success w-100") { "▶ Process Batch" }
            end
            div(class: "mt-half") do
              a(href: warehouse_batch_path(@batch), class: "text-muted") { "Cancel" }
            end
          end
        end
      end
    end
  end
end
