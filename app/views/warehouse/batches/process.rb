# frozen_string_literal: true

class Views::Warehouse::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-container--narrow") do
      div(class: "page-title-group mb-3") do
        render Primer::Beta::Button.new(tag: :a, href: warehouse_batch_path(@batch), scheme: :invisible, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back to batch"
        end
        h1(class: "page-title") { "Process Warehouse Batch ##{@batch.id}" }
      end

      render Primer::Alpha::Banner.new(scheme: :default, mb: 4) do
        "This will create #{helpers.pluralize(@batch.addresses.count, 'warehouse order')}."
      end

      # Line Items
      render Primer::Beta::BorderBox.new(mb: 4) do |box|
        box.with_header do |header|
          header.with_title(tag: :h3) { "Template: #{@batch.warehouse_template.name}" }
        end
        @batch.warehouse_template.line_items.each do |line_item|
          box.with_row do
            div(class: "kv-row") do
              span { "#{line_item.quantity}x #{line_item.sku.name}" }
            end
          end
        end
      end

      # Cost Breakdown
      render Primer::Beta::BorderBox.new(mb: 4) do |box|
        box.with_header do |header|
          header.with_title(tag: :h3) { "Cost Breakdown" }
        end
        box.with_body do
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
      end

      # Submit
      div(class: "page-actions") do
        render Primer::Beta::Button.new(tag: :a, href: warehouse_batch_path(@batch), scheme: :secondary) do
          "Cancel"
        end
        form(method: :post, action: process_batch_warehouse_batch_path(@batch), class: "form-inline") do
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :play)
            "do it!"
          end
        end
      end
    end
  end
end
