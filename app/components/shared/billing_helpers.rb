# frozen_string_literal: true

module Components::Shared::BillingHelpers
  private

  def state_badge(state)
    variant = case state
              when "settled" then "badge-success"
              when "pending" then "badge-warning"
              when "voided" then "badge"
              end
    span(class: "badge #{variant}") { state }
  end

  def transfer_cell(transfer)
    return span(class: "text-muted") { "—" } unless transfer
    variant = case transfer.state
              when "completed" then "badge-success"
              when "pending" then "badge-warning"
              when "unknown" then "badge-warning"
              when "failed" then "badge-danger"
              end
    span(class: "badge #{variant}", title: transfer.last_error) { transfer.state }
    plain " "
    code(class: "text-muted", title: transfer.idempotency_key) { transfer.remote_id&.truncate(16) || transfer.idempotency_key }
  end

  def ledgerable_link(entry)
    case entry.ledgerable_type
    when "Warehouse::Order"
      order = entry.ledgerable
      a(href: warehouse_order_path(order)) { order.hc_id || "Order ##{order.id}" }
    when "Batch"
      batch = entry.ledgerable
      a(href: letter_batch_path(batch)) { batch.public_id }
    when "USPS::Indicium"
      indicium = entry.ledgerable
      if indicium.letter.present?
        a(href: letter_path(indicium.letter)) { "Indicium #{indicium.public_id}" }
      else
        plain "Indicium #{indicium.public_id}"
      end
    else
      plain "#{entry.ledgerable_type} ##{entry.ledgerable_id}"
    end
  end

  def ledgerable_detail(entry)
    case entry.ledgerable_type
    when "Warehouse::Order"
      order = entry.ledgerable
      a(href: warehouse_order_path(order)) do
        plain "#{order.user_facing_title || "Warehouse Order"} (#{order.hc_id})"
      end
    when "Batch"
      batch = entry.ledgerable
      a(href: letter_batch_path(batch)) { "Letter Batch #{batch.public_id}" }
    when "USPS::Indicium"
      indicium = entry.ledgerable
      if indicium.letter.present?
        a(href: letter_path(indicium.letter)) { "Indicium #{indicium.public_id} → Letter #{indicium.letter.public_id}" }
      else
        plain "Indicium #{indicium.public_id}"
      end
    else
      plain "#{entry.ledgerable_type} ##{entry.ledgerable_id}"
    end
  end
end
