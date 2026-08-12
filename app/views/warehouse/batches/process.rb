# frozen_string_literal: true

class Views::Warehouse::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: warehouse_batch_path(@batch), style: "text-decoration: none; color: var(--foreground2);") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Process Warehouse Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        div(class: "banner", style: "margin-bottom: 1rem;") do
          plain "This will create #{helpers.pluralize(@batch.addresses.count, 'warehouse order')}."
        end

        section(style: "margin-bottom: 1rem;") do
          strong { "Template: #{@batch.warehouse_template.name}" }
          hr
          div(style: "margin-top: 0.5rem;") do
            @batch.warehouse_template.line_items.each do |line_item|
              div { "#{line_item.quantity}× #{line_item.sku.name}" }
            end
          end
        end

        section(style: "margin-bottom: 1rem;") do
          strong { "Cost Breakdown" }
          hr
          div(class: "detail-grid", style: "margin-top: 0.5rem;") do
            span(class: "detail-label") { "Contents" }
            span { number_to_currency(@batch.contents_cost) }
            span(class: "detail-label") { "Labor" }
            span { number_to_currency(@batch.labor_cost) }
            span(class: "detail-label") { "Postage" }
            span(style: "color: var(--foreground2);") { "TBD" }
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
          div(style: "margin-top: 0.5rem;") do
            form(method: :post, action: process_batch_warehouse_batch_path(@batch)) do
              input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
              button(type: "submit", class: "btn-success", style: "width: 100%;") { "▶ Process Batch" }
            end
            div(style: "margin-top: 0.5rem;") do
              a(href: warehouse_batch_path(@batch), style: "color: var(--foreground2);") { "Cancel" }
            end
          end
        end
      end
    end
  end
end
