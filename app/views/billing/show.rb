# frozen_string_literal: true

class Views::Billing::Show < Views::Base
  def initialize(ledger_entry:)
    @entry = ledger_entry
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Billing Entry ##{@entry.id}",
    )

    section do
      div(class: "detail-grid") do
        span(class: "detail-label") { "Category" }
        span { span(class: "badge badge-info") { @entry.category } }

        span(class: "detail-label") { "Amount" }
        span(style: "font-weight:600;font-size:1.25em;") { money(@entry.amount_cents) }

        if @entry.reverses.present?
          span(class: "detail-label") { "Credit against" }
          span { a(href: billing_path(@entry.reverses)) { "entry ##{@entry.reverses.id} ($#{"%.2f" % @entry.reverses.amount})" } }
        end

        if @entry.reversals.any?
          span(class: "detail-label") { "Credits" }
          span do
            @entry.reversals.each do |credit|
              a(href: billing_path(credit)) { money(credit.amount_cents) }
              plain " "
            end
            plain "(net #{money(@entry.net_cents)})"
          end
        end

        span(class: "detail-label") { "State" }
        span { state_badge(@entry.state) }

        span(class: "detail-label") { "Organization" }
        span { @entry.billing_profile.organization_name }

        span(class: "detail-label") { "Created" }
        span(class: "text-muted") { @entry.created_at.strftime("%b %d, %Y %H:%M") }

        if @entry.settled_at.present?
          span(class: "detail-label") { "Settled" }
          span(class: "text-muted") { @entry.settled_at.strftime("%b %d, %Y %H:%M") }
        end

        span(class: "detail-label") { "For" }
        span { ledgerable_detail(@entry) }

        if (t = @entry.hcb_transfer).present?
          span(class: "detail-label") { "HCB Transfer" }
          span do
            span(class: "badge") { "#{t.direction} · #{t.state}" }
            plain " "
            code { t.remote_id || t.idempotency_key }
            if t.last_error.present?
              div(class: "text-muted") { t.last_error }
            end
            if t.attempts > 0
              div(class: "text-muted") { "#{t.attempts} attempt(s)#{t.next_attempt_at ? ", next #{t.next_attempt_at.strftime("%b %d %H:%M")}" : ""}" }
            end
          end
        end

        if @entry.metadata.present? && @entry.metadata.any?
          span(class: "detail-label") { "Metadata" }
          span do
            pre(style: "margin:0;font-size:0.85em;") { JSON.pretty_generate(@entry.metadata) }
          end
        end
      end
    end
  end

  private

  def money(cents)
    sign = cents.negative? ? "-" : ""
    "#{sign}$#{"%.2f" % (cents.abs / 100.0)}"
  end

  def state_badge(state)
    variant = case state
              when "settled" then "badge-success"
              when "pending" then "badge-warning"
              when "voided" then "badge"
              end
    span(class: "badge #{variant}") { state }
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
