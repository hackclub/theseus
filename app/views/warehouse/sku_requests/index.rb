# frozen_string_literal: true

class Views::Warehouse::SKURequests::Index < Views::Base
  def initialize(sku_requests:)
    @sku_requests = sku_requests
  end

  def view_template
    pending_count = @sku_requests.select { |r| r.aasm_state == "submitted" }.size

    render Components::Shared::PageToolbar.new(
      title: "SKU Requests",
      action_href: new_warehouse_sku_request_path,
      action_label: "+ New Request"
    )

    if current_user.warehouse_czar? && pending_count > 0
      div(class: "banner banner-info", style: "margin-bottom: 1rem;") do
        strong { "#{pending_count} request#{pending_count == 1 ? '' : 's'} pending review" }
      end
    end

    if @sku_requests.empty?
      div(style: "text-align: center; padding: 3rem 0; color: GrayText;") do
        p { "No SKU requests yet." }
        a(href: new_warehouse_sku_request_path) do
          button(class: "btn-success") { "+ New Request" }
        end
      end
    else
      table do
        thead do
          tr do
            th { "Name" }
            th { "Category" }
            th { "Status" }
            th { "Requested By" }
            th { "Date" }
            th(style: "text-align: right;") { "" }
          end
        end
        tbody do
          @sku_requests.each do |req|
            tr do
              td do
                a(href: warehouse_sku_request_path(req), style: "text-decoration:none;font-weight:600;") { req.name }
              end
              td { span(class: "badge") { req.category&.humanize || "—" } }
              td { status_badge(req.aasm_state) }
              td(class: "text-muted") { req.user&.username || "—" }
              td(class: "text-muted") { req.created_at.strftime("%b %d, %Y") }
              td(style: "text-align:right;") do
                if policy(req).edit?
                  a(href: edit_warehouse_sku_request_path(req), style: "color:GrayText;margin-right:0.5rem;") { "✎" }
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def status_badge(state)
    css = case state.to_s
    when "draft" then ""
    when "submitted" then "badge-info"
    when "approved", "synced" then "badge-success"
    when "rejected" then "badge-danger"
    else ""
    end
    span(class: "badge #{css}".strip) { state.to_s.humanize }
  end
end
