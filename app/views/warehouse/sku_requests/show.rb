# frozen_string_literal: true

class Views::Warehouse::SKURequests::Show < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(sku_request:)
    @sku_request = sku_request
  end

  def view_template
    toolbar

    div(class: "show-layout") do
      div(class: "show-main") do
        returned_banner if @sku_request.returned?
        summary_banner
        action_section
        details_section
      end

      div(class: "show-sidebar") do
        image_section if @sku_request.image.attached?
        blocking_pos_section if @sku_request.blocking_purchase_orders.any?
        timestamps_section
      end
    end
  end

  private

  def toolbar
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: warehouse_sku_requests_path, class: "link-muted") { "← SKU Requests" }
        strong(class: "text-title") { @sku_request.name }
        status_badge(@sku_request.aasm_state)
      end
      span(class: "spacer")
      div(class: "flex-row") do
        if @sku_request.draft?
          draft_actions
        elsif @sku_request.returned?
          returned_actions
        end
      end
    end
  end

  def draft_actions
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
        onclick: safe("return confirm('Submit this SKU request for czar review?')")
    end
  end

  def returned_actions
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
        onclick: safe("return confirm('Resubmit this SKU request for czar review?')")
    end
  end

  def returned_banner
    section(class: "sku-request-returned-banner") do
      div(class: "sku-request-returned-content") do
        span(class: "sku-request-returned-icon") { "⚠" }
        div do
          strong { "Returned for revision" }
          if @sku_request.reviewed_by
            plain " by #{@sku_request.reviewed_by.username}"
          end
          if @sku_request.reviewer_notes.present?
            div(class: "sku-request-returned-notes") do
              span(class: "detail-label") { "Notes: " }
              span { @sku_request.reviewer_notes }
            end
          end
        end
      end
    end
  end

  def summary_banner
    section(class: "mb-1") do
      div(class: "sku-request-summary-row") do
        div do
          span(class: "detail-label") { "Requested by " }
          strong { @sku_request.user&.username || "—" }
          if @sku_request.submitted_at
            span(class: "text-muted") { " on #{@sku_request.submitted_at.strftime('%b %d, %Y')}" }
          end
        end
        if @sku_request.expected_arrival
          div do
            span(class: "detail-label") { "Arriving " }
            strong { @sku_request.expected_arrival.strftime("%b %d, %Y") }
          end
        end
        if @sku_request.expected_quantity
          div do
            span(class: "detail-label") { "Quantity " }
            strong { @sku_request.expected_quantity.to_s }
          end
        end
        div do
          span(class: "detail-label") { "Category " }
          span(class: "badge") { @sku_request.category&.humanize || "—" }
        end
        div do
          span(class: "detail-label") { "Program " }
          strong { @sku_request.program.presence || "—" }
        end
      end
    end
  end

  def action_section
    case @sku_request.aasm_state
    when "submitted"
      czar_review_form if policy(@sku_request).approve?
    when "approved", "synced"
      approved_info
    when "returned"
      returned_info
    end
  end

  def czar_review_form
    section(class: "mb-1") do
      strong { "Review & Approve" }
      hr

      form(method: "post", action: approve_warehouse_sku_request_path(@sku_request)) do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)

        div(class: "sku-request-review-grid") do
          # SKU code — the big one
          div(class: "sku-request-review-grid__full") do
            label(class: "label-block text-muted") do
              plain "Assigned SKU Code "
              span(class: "text-danger") { "*" }
            end
            input(
              type: "text",
              name: "assigned_sku_code",
              required: true,
              value: @sku_request.suggested_code,
              placeholder: "e.g. Sti/Ath/Tes",
              class: "w-100 mono sku-request-code-input"
            )
            small(class: "text-muted sku-request-review-hint") do
              plain "Format: Category/Program/Name (3 letters each, but longer is ok)"
            end
          end

          # Editable fields the czar can adjust
          div do
            label(class: "label-block text-muted") { "Unit Cost" }
            div(class: "sku-request-unit-cost-row") do
              span { "$" }
              input(type: "number", name: "unit_cost_override", step: "0.01", value: (@sku_request.unit_cost ? "%.2f" % @sku_request.unit_cost : nil), class: "w-100")
            end
          end

          div do
            label(class: "label-block text-muted") { "Country of Origin" }
            input(type: "text", name: "country_of_origin_override", value: @sku_request.country_of_origin, class: "w-100")
          end

          div do
            label(class: "label-block text-muted") { "HS Code" }
            input(type: "text", name: "hs_code_override", value: @sku_request.hs_code, class: "w-100")
          end

          div do
            label(class: "label-block text-muted") { "Customs Description" }
            input(type: "text", name: "customs_description_override", value: @sku_request.customs_description, class: "w-100")
          end
        end

        div(class: "sku-request-approve-actions") do
          button(type: "submit", class: "btn-success", onclick: safe("return confirm('Approve this SKU request and create the SKU in Zenventory?')")) { "✓ Approve & Create SKU" }
        end
      end

      # Return for revision — separate form, visually secondary
      hr
      div(class: "mt-half") do
        form(method: "post", action: reject_warehouse_sku_request_path(@sku_request)) do
          input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
          div(class: "sku-request-return-row") do
            div(class: "flex-1") do
              label(class: "label-block text-muted") { "Reviewer Notes (optional)" }
              input(type: "text", name: "reviewer_notes", placeholder: "Notes for the requester...", class: "w-100")
            end
            button(type: "submit", class: "btn-warning btn-sm", onclick: safe("return confirm('Return this SKU request for revision?')")) { "↩ Return for Revision" }
          end
        end
      end
    end
  end

  def approved_info
    section(class: "mb-1") do
      strong { "✓ Approved" }
      hr
      div(class: "detail-grid mt-half") do
        span(class: "detail-label") { "SKU Code" }
        if @sku_request.warehouse_sku
          a(href: warehouse_sku_path(@sku_request.warehouse_sku), class: "fw-600 mono") { @sku_request.assigned_sku_code }
        else
          span(class: "fw-600 mono") { @sku_request.assigned_sku_code }
        end
        span(class: "detail-label") { "Reviewed By" }
        span { @sku_request.reviewed_by&.username || "—" }
        span(class: "detail-label") { "Reviewed At" }
        span(class: "text-muted") { @sku_request.reviewed_at&.strftime("%b %d, %Y %H:%M") || "—" }
      end

      if @sku_request.image.attached? && @sku_request.warehouse_sku&.zenventory_url.present?
        hr
        div(class: "sku-request-zenventory-box") do
          strong(class: "sku-request-zenventory-title") { "📷 Upload this image to Zenventory" }
          p(class: "sku-request-zenventory-desc") do
            plain "Zenventory doesn't support image upload via API — download it here and upload it in their UI."
          end
          div(class: "flex-row") do
            a(
              href: helpers.rails_blob_path(@sku_request.image, disposition: "attachment"),
              class: "btn-sm btn-success no-underline"
            ) { "⬇ Download Image" }
            a(
              href: @sku_request.warehouse_sku.zenventory_url,
              target: "_blank",
              class: "btn-sm btn-info no-underline"
            ) { "↗ Edit in Zenventory" }
          end
        end
      end
    end
  end

  def returned_info
    section(class: "mb-1") do
      strong { "Review History" }
      hr
      div(class: "detail-grid mt-half") do
        span(class: "detail-label") { "Reviewed By" }
        span { @sku_request.reviewed_by&.username || "—" }
        span(class: "detail-label") { "Reviewed At" }
        span(class: "text-muted") { @sku_request.reviewed_at&.strftime("%b %d, %Y %H:%M") || "—" }
      end
    end
  end

  def details_section
    section(class: "mb-1") do
      strong { "Request Details" }
      hr
      div(class: "detail-grid mt-half") do
        detail_row("Name", @sku_request.name)
        detail_row("Description", @sku_request.description)
        detail_row("Category", @sku_request.category&.humanize)
        detail_row("Unit Cost", @sku_request.unit_cost ? number_to_currency(@sku_request.unit_cost) : nil)
        detail_row("Country of Origin", @sku_request.country_of_origin)
        detail_row("HS Code", @sku_request.hs_code)
        detail_row("Customs Description", @sku_request.customs_description)
        if @sku_request.suggested_code.present?
          span(class: "detail-label") { "Suggested SKU Code" }
          span(class: "mono") { @sku_request.suggested_code }
        end
      end
    end
  end

  def detail_row(label, value)
    span(class: "detail-label") { label }
    span { value.present? ? value.to_s : "—" }
  end

  def image_section
    section(class: "mb-1") do
      strong { "Image" }
      hr
      div(class: "mt-half") do
        img(
          src: helpers.url_for(@sku_request.image),
          class: "sku-request-image",
          alt: @sku_request.name
        )
      end
    end
  end

  def blocking_pos_section
    pos = @sku_request.blocking_purchase_orders
    section(class: "mb-1") do
      strong { "Blocking Purchase Orders" }
      hr
      div(class: "mt-half") do
        p(class: "text-muted mb-half") do
          plain "This SKU request is blocking #{pos.size} purchase order#{pos.size == 1 ? '' : 's'}."
        end
        ul do
          pos.each do |po|
            li do
              a(href: warehouse_purchase_order_path(po), class: "link-strong") do
                plain "PO ##{po.id}"
              end
              span(class: "text-muted") { " — #{po.humanized_state}" }
            end
          end
        end
      end
    end
  end

  def timestamps_section
    section(class: "mb-1") do
      strong { "Timestamps" }
      hr
      div(class: "detail-grid mt-half") do
        span(class: "detail-label") { "Created" }
        span(class: "text-muted") { @sku_request.created_at.strftime("%b %d, %Y %H:%M") }
        span(class: "detail-label") { "Updated" }
        span(class: "text-muted") { @sku_request.updated_at.strftime("%b %d, %Y %H:%M") }
        if @sku_request.submitted_at
          span(class: "detail-label") { "Submitted" }
          span(class: "text-muted") { @sku_request.submitted_at.strftime("%b %d, %Y %H:%M") }
        end
        if @sku_request.reviewed_at
          span(class: "detail-label") { "Reviewed" }
          span(class: "text-muted") { @sku_request.reviewed_at.strftime("%b %d, %Y %H:%M") }
        end
      end
    end
  end

  def status_badge(state)
    css = case state.to_s
    when "draft" then ""
    when "submitted" then "badge-info"
    when "approved", "synced" then "badge-success"
    when "returned" then "badge-warning"
    else ""
    end
    span(class: "badge #{css}".strip) { state.to_s.humanize }
  end
end
