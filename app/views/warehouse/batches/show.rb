# frozen_string_literal: true

class Views::Warehouse::Batches::Show < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(
        title: "Warehouse Batch ##{@batch.id}",
        subtitle: "#{helpers.pluralize(@batch.addresses.count, 'address')}"
      ) do |header|
        header.with_actions do
          render Primer::Beta::Button.new(tag: :a, href: warehouse_batches_path, scheme: :secondary, size: :small) do |btn|
            btn.with_leading_visual_icon(icon: :"arrow-left")
            "Back"
          end
          render Primer::Beta::Button.new(tag: :a, href: edit_warehouse_batch_path(@batch), scheme: :secondary, size: :small) do |btn|
            btn.with_leading_visual_icon(icon: :pencil)
            "Edit"
          end
          if @batch.fields_mapped?
            render Primer::Beta::Button.new(tag: :a, href: process_confirm_warehouse_batch_path(@batch), scheme: :primary, size: :small) do |btn|
              btn.with_leading_visual_icon(icon: :play)
              "Process"
            end
          end
        end
      end

      batch_details
      orders_section if @batch.orders.any?
      addresses_section if @batch.addresses.any?
      danger_zone
    end
  end

  private

  def batch_details
    render Primer::Beta::BorderBox.new(mb: 4) do |box|
      box.with_header do |header|
        header.with_title(tag: :h3) { "Details" }
      end
      box.with_body do
        dl(class: "detail-dl") do
          detail_row("Status") { render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch) }
          detail_row("Template") { plain @batch.warehouse_template&.name || "—" }
          detail_row("Title") { plain @batch.warehouse_user_facing_title || "—" }
          detail_row("Created") { plain "#{time_ago_in_words(@batch.created_at)} ago" }

          if @batch.tags.any?
            detail_row("Tags") { render Components::Shared::Tags.new(tags: @batch.tags) }
          end

          if @batch.processed?
            detail_row("Contents Cost") { plain number_to_currency(@batch.contents_cost) }
            detail_row("Labor Cost") { plain number_to_currency(@batch.labor_cost) }
            detail_row("Total Cost") { strong { number_to_currency(@batch.total_cost) } }
          end
        end
      end
    end
  end

  def detail_row(label)
    dt { label }
    dd { yield }
  end

  def orders_section
    details(class: "collapsible-section") do
      summary(class: "collapsible-summary") do
        "Orders (#{@batch.orders.count})"
      end
      div(class: "collapsible-body") do
        table(class: "data-table") do
          thead do
            tr do
              %w[ID Recipient Status].each do |h|
                th { h }
              end
            end
          end
          tbody do
            @batch.orders.includes(:address).limit(100).each do |order|
              tr do
                td do
                  a(href: warehouse_order_path(order)) { order.public_id }
                end
                td do
                  plain "#{order.address&.first_name} #{order.address&.last_name}"
                end
                td do
                  render Components::Shared::StatusBadge.new(status: order.aasm_state, type: :warehouse_order)
                end
              end
            end
          end
        end
      end
    end
  end

  def addresses_section
    details(class: "collapsible-section") do
      summary(class: "collapsible-summary") do
        "Addresses (#{@batch.addresses.count})"
      end
      div(class: "collapsible-body") do
        table(class: "data-table") do
          thead do
            tr do
              %w[Name Address City State ZIP Country].each do |h|
                th { h }
              end
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

  def danger_zone
    div(class: "danger-zone") do
      h3 { "Danger Zone" }
      p(class: "danger-zone-desc") { "This action cannot be undone." }
      form(method: :post, action: warehouse_batch_path(@batch)) do
        input(type: :hidden, name: :_method, value: :delete)
        input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
        render Primer::Beta::Button.new(type: :submit, scheme: :danger) do |btn|
          btn.with_leading_visual_icon(icon: :trash)
          "Delete this batch"
        end
      end
    end
  end
end
