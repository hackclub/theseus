# frozen_string_literal: true

class Views::Letter::InstantQueues::Show < Views::Letter::Queues::ShowBase
  private

  def type_label = "Instant"

  def edit_queue_path
    edit_letter_instant_queue_path(queue)
  end

  def queue_show_path(**params)
    letter_instant_queue_path(queue, **params)
  end

  # --- Instant-specific details ---

  def extra_queue_details
    div("is-": "separator")
    div(style: "padding: 1lh 1ch;") do
      strong { "Template" }
      div(class: "detail-value") { queue.template.presence || "—" }
    end

    div("is-": "separator")
    div(style: "padding: 1lh 1ch;") do
      strong { "Postage Type" }
      div(class: "detail-value") { queue.postage_type&.humanize || "—" }
    end

    if queue.usps_payment_account.present?
      div("is-": "separator")
      div(style: "padding: 1lh 1ch;") do
        strong { "USPS Payment Account" }
        div(class: "detail-value") { queue.usps_payment_account.display_name }
      end
    end

    if queue.hcb_payment_account.present?
      div("is-": "separator")
      div(style: "padding: 1lh 1ch;") do
        strong { "HCB Payment Account" }
        div(class: "detail-value") { queue.hcb_payment_account.organization_name }
      end
    end

    div("is-": "separator")
    div(style: "padding: 1lh 1ch;") do
      strong { "QR Code" }
      div(class: "detail-value") { queue.include_qr_code ? "Enabled" : "Disabled" }
    end
  end
end
