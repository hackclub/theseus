# frozen_string_literal: true

class Views::Warehouse::SKURequests::Show < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(sku_request:)
    @sku_request = sku_request
  end

  def view_template
    toolbar
    action_section
    details_section
    image_section if @sku_request.image.attached?
    blocking_pos_section if @sku_request.blocking_purchase_orders.any?
  end

  private

  def toolbar
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: warehouse_sku_requests_path, style: "text-decoration: none; color: GrayText;") { "← SKU Requests" }
        strong(style: "font-size: 1.15em;") { @sku_request.name }
        status_badge(@sku_request.aasm_state)
      end
      span(class: "spacer")
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        if @sku_request.draft?
          if policy(@sku_request).edit?
            a(href: edit_warehouse_sku_request_path(@sku_request)) do
              button(class: "btn-sm") { "✎ Edit" }
            end
          end
          if policy(@sku_request).submit?
            button_to "Submit for Review",
              submit_warehouse_sku_request_path(@sku_request),
              method: :post,
              class: "btn-success btn-sm",
              onclick: "return confirm('Submit this SKU request for czar review?')"
          end
        end
      end
    end
  end


  def action_section
    case @sku_request.aasm_state
    when "submitted"
      czar_actions if policy(@sku_request).approve?
    when "approved", "synced"
      approved_info
    when "rejected"
      rejected_info
    end
  end

  def czar_actions
    section(style: "margin-bottom: 1rem;") do
      strong { "Review" }
      hr

      # Approve with SKU code
      div(style: "margin-top: 0.5rem; margin-bottom: 1rem;") do
        form(method: "post", action: approve_warehouse_sku_request_path(@sku_request)) do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          div(style: "display:flex;align-items:flex-end;gap:0.5rem;") do
            div(style: "flex:1;") do
              label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "Assigned SKU Code *" }
              input(
                type: "text",
                name: "assigned_sku_code",
                required: true,
                placeholder: "e.g. STK-ATHENA-001",
                style: "width:100%;"
              )
            end
            button(type: "submit", class: "btn-success", onclick: "return confirm('Approve this SKU request and create the SKU?')") { "✓ Approve" }
          end
        end
      end

      # Reject
      div do
        form(method: "post", action: reject_warehouse_sku_request_path(@sku_request)) do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          div(style: "display:flex;align-items:flex-end;gap:0.5rem;") do
            div(style: "flex:1;") do
              label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "Rejection Reason (optional)" }
              input(
                type: "text",
                name: "rejection_reason",
                placeholder: "Reason for rejection...",
                style: "width:100%;"
              )
            end
            button(type: "submit", class: "btn-danger", onclick: "return confirm('Reject this SKU request?')") { "✕ Reject" }
          end
        end
      end
    end
  end

  def approved_info
    section(style: "margin-bottom: 1rem;") do
      strong { "Approval" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "Assigned SKU Code" }
        if @sku_request.warehouse_sku
          a(href: warehouse_sku_path(@sku_request.warehouse_sku), style: "font-weight:600;") { @sku_request.assigned_sku_code }
        else
          span(style: "font-weight:600;") { @sku_request.assigned_sku_code }
        end
        span(class: "detail-label") { "Reviewed By" }
        span { @sku_request.reviewed_by&.name || "—" }
        span(class: "detail-label") { "Reviewed At" }
        span(class: "text-muted") { @sku_request.reviewed_at&.strftime("%b %d, %Y %H:%M") || "—" }
      end
    end
  end

  def rejected_info
    section(style: "margin-bottom: 1rem;") do
      strong { "Rejection" }
      hr
      div(style: "margin-top: 0.5rem;") do
        if @sku_request.rejection_reason.present?
          div(style: "margin-bottom: 0.5rem;") do
            span(class: "detail-label") { "Reason: " }
            span { @sku_request.rejection_reason }
          end
        end
        div(class: "text-muted") do
          plain "Please contact "
          strong { @sku_request.user&.username || "the requester" }
          plain " to discuss."
        end
        if @sku_request.reviewed_by
          div(class: "text-muted", style: "margin-top: 0.25rem;") do
            plain "Reviewed by #{@sku_request.reviewed_by.username}"
            if @sku_request.reviewed_at
              plain " on #{@sku_request.reviewed_at.strftime('%b %d, %Y %H:%M')}"
            end
          end
        end
      end
    end
  end

  def details_section
    section(style: "margin-bottom: 1rem;") do
      strong { "Details" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        detail_row("Name", @sku_request.name)
        detail_row("Description", @sku_request.description)
        detail_row("Category", @sku_request.category&.humanize)
        detail_row("Unit Cost", @sku_request.unit_cost ? number_to_currency(@sku_request.unit_cost) : nil)
        detail_row("Country of Origin", @sku_request.country_of_origin)
        detail_row("HS Code", @sku_request.hs_code)
        detail_row("Customs Description", @sku_request.customs_description)
        detail_row("Program", @sku_request.program)
        detail_row("Expected Arrival", @sku_request.expected_arrival&.strftime("%b %d, %Y"))
        detail_row("Expected Quantity", @sku_request.expected_quantity&.to_s)
        detail_row("Suggested SKU Code", @sku_request.suggested_sku_code)
        detail_row("Requested By", @sku_request.user&.username)
        detail_row("Created", @sku_request.created_at.strftime("%b %d, %Y %H:%M"))
        if @sku_request.submitted_at
          detail_row("Submitted", @sku_request.submitted_at.strftime("%b %d, %Y %H:%M"))
        end
      end
    end
  end

  def detail_row(label, value)
    span(class: "detail-label") { label }
    span { value.present? ? value.to_s : "—" }
  end

  def image_section
    section(style: "margin-bottom: 1rem;") do
      strong { "Image" }
      hr
      div(style: "margin-top: 0.5rem;") do
        img(
          src: helpers.url_for(@sku_request.image),
          style: "max-width: 300px; max-height: 300px; border-radius: 4px;",
          alt: @sku_request.name
        )
      end
    end
  end

  def blocking_pos_section
    pos = @sku_request.blocking_purchase_orders
    section(style: "margin-bottom: 1rem;") do
      strong { "Blocking Purchase Orders" }
      hr
      div(style: "margin-top: 0.5rem;") do
        p(class: "text-muted", style: "margin-bottom: 0.5rem;") do
          plain "This SKU request is blocking #{pos.size} purchase order#{pos.size == 1 ? '' : 's'}."
        end
        ul do
          pos.each do |po|
            li do
              a(href: warehouse_purchase_order_path(po), style: "text-decoration:none;font-weight:600;") do
                plain "PO ##{po.id}"
              end
              span(class: "text-muted") { " — #{po.aasm_state.humanize}" }
            end
          end
        end
      end
    end
  end

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
