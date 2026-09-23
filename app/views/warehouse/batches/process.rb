# frozen_string_literal: true

class Views::Warehouse::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  # The controller runs preflight before rendering, so errors mean unmailable rows.
  def blocked? = @batch.errors.any?

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: warehouse_batch_path(@batch), class: "link-muted") { "← Batch ##{@batch.id}" }
        strong(class: "text-title") { "Process Warehouse Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        if blocked?
          div(class: "banner banner-error mb-1") do
            strong { "These rows can't be shipped yet:" }
            ul(class: "mt-half") do
              @batch.errors.each { |error| li { error.message } }
            end
          end
        else
          div(class: "banner mb-1") do
            plain "This will create #{helpers.pluralize(@batch.addresses.count, 'warehouse order')}."
          end
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
            span(class: "text-muted") { "at cost, as orders ship" }
          end
        end

        if blocked?
          div(class: "flex-row") do
            a(href: warehouse_batch_path(@batch)) { "← Back to batch" }
            span(class: "text-muted") { "Fix the addresses above, then come back." }
          end
        else
          form(method: :post, action: process_batch_warehouse_batch_path(@batch)) do
            input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
            render Components::MoneyNotice.new(
              lines: @batch.billing_lines,
              profiles: @batch.user.billing_profiles,
              field: "batch[hcb_payment_account_id]",
              selected: @batch.billing_profile,
              unbilled: @batch.user.billing_profiles.none?,
              proceed: "Process Batch",
              cancel_href: warehouse_batch_path(@batch),
            )
          end
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "What happens" }
          hr
          div(class: "mt-half text-muted") do
            plain "Every address becomes a warehouse order and is sent to Zenventory. Labor is charged to the HCB organization you pick, once, for the whole batch. Postage is charged per order, at cost, when it ships."
          end
        end
      end
    end
  end
end
