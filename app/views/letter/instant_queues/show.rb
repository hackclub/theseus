# frozen_string_literal: true

class Views::Letter::InstantQueues::Show < Views::Letter::Queues::ShowBase
  private

  def type_label = "Instant"

  def type_badge
    span(class: "badge badge-success") { "Instant" }
  end

  def edit_queue_path
    edit_letter_instant_queue_path(queue)
  end

  def queue_show_path(**params)
    letter_instant_queue_path(queue, **params)
  end

  # --- Instant-specific detail rows (inside detail-grid) ---

  def extra_queue_details
    span(class: "detail-label") { "Template" }
    span { queue.template.presence || "—" }

    span(class: "detail-label") { "Postage Type" }
    span { queue.postage_type&.humanize || "—" }

    if queue.usps_payment_account.present?
      span(class: "detail-label") { "USPS Payment" }
      span { queue.usps_payment_account.display_name }
    end

    if queue.hcb_payment_account.present?
      span(class: "detail-label") { "HCB Payment" }
      span { queue.hcb_payment_account.organization_name }
    end

    span(class: "detail-label") { "QR Code" }
    span { queue.include_qr_code ? "Enabled" : "Disabled" }
  end
end
