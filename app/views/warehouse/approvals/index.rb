# frozen_string_literal: true

class Views::Warehouse::Approvals::Index < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(pending_sku_requests:, pending_pos:, blocked_pos:)
    @pending_sku_requests = pending_sku_requests
    @pending_pos = pending_pos
    @blocked_pos = blocked_pos
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Approval Queue",
      jumpcode_path: warehouse_approvals_path
    )

    pending_sku_requests_section
    pending_pos_section
    blocked_pos_section if @blocked_pos.any?
  end

  private

  def pending_sku_requests_section
    section(class: "approval-section") do
      h2(class: "flex-row") do
        plain "Pending SKU Requests"
        span(class: "badge") { @pending_sku_requests.size.to_s }
      end

      if @pending_sku_requests.empty?
        div(class: "approval-empty") do
          span(class: "text-muted") { "No pending SKU requests" }
        end
      else
        table do
          thead do
            tr do
              th { "Name" }
              th { "Category" }
              th { "Requested By" }
              th { "Submitted" }
              th(class: "text-right") { "" }
            end
          end
          tbody do
            @pending_sku_requests.each do |req|
              tr do
                td(class: "fw-600") { req.name }
                td(class: "text-muted") { req.category&.humanize }
                td(class: "text-muted") { req.user&.username || "—" }
                td(class: "text-muted") { req.submitted_at&.strftime("%b %d, %Y %H:%M") || "—" }
                td(class: "text-right") do
                  a(href: warehouse_sku_request_path(req), class: "link-strong") { "Review →" }
                end
              end
            end
          end
        end
      end
    end
  end

  def pending_pos_section
    section(class: "approval-section") do
      h2(class: "flex-row") do
        plain "Pending Purchase Orders"
        span(class: "badge") { @pending_pos.size.to_s }
      end

      if @pending_pos.empty?
        div(class: "approval-empty") do
          span(class: "text-muted") { "No pending purchase orders" }
        end
      else
        table do
          thead do
            tr do
              th { "Order #" }
              th { "Supplier" }
              th { "Items" }
              th { "Total Cost" }
              th { "Submitted By" }
              th { "Submitted" }
              th(class: "text-right") { "" }
            end
          end
          tbody do
            @pending_pos.each do |po|
              tr do
                td(class: "fw-600") { po.order_number.presence || "##{po.id}" }
                td(class: "text-muted") { po.supplier_name }
                td(class: "text-muted") { po.line_items.size.to_s }
                td(class: "text-muted") { number_to_currency(po.total_cost) }
                td(class: "text-muted") { po.user&.username || "—" }
                td(class: "text-muted") { po.submitted_at&.strftime("%b %d, %Y %H:%M") || "—" }
                td(class: "text-right") do
                  a(href: warehouse_purchase_order_path(po), class: "link-strong") { "Review →" }
                end
              end
            end
          end
        end
      end
    end
  end

  def blocked_pos_section
    section(class: "approval-section") do
      h2(class: "flex-row") do
        plain "Approved but Blocked POs"
        span(class: "badge badge-warning") { @blocked_pos.size.to_s }
      end

      table do
        thead do
          tr do
            th { "Order #" }
            th { "Supplier" }
            th { "Blocking SKU Requests" }
            th(class: "text-right") { "" }
          end
        end
        tbody do
          @blocked_pos.each do |po|
            tr do
              td(class: "fw-600") { po.order_number.presence || "##{po.id}" }
              td(class: "text-muted") { po.supplier_name }
              td do
                po.unresolved_sku_requests.each_with_index do |req, i|
                  plain ", " if i > 0
                  a(href: warehouse_sku_request_path(req), class: "no-underline") { req.name }
                end
              end
              td(class: "text-right") do
                a(href: warehouse_purchase_order_path(po), class: "link-strong") { "View →" }
              end
            end
          end
        end
      end
    end
  end
end
