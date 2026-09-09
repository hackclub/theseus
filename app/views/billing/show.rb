# frozen_string_literal: true

class Views::Billing::Show < Views::Base
  include Components::Shared::BillingHelpers

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
        span(class: "fw-600 text-lg") { number_to_currency(@entry.amount_cents / 100.0) }

        if @entry.reverses.present?
          span(class: "detail-label") { "Credit against" }
          span { a(href: billing_path(@entry.reverses)) { "entry ##{@entry.reverses.id} ($#{"%.2f" % @entry.reverses.amount})" } }
        end

        if @entry.reversals.any?
          span(class: "detail-label") { "Credits" }
          span do
            @entry.reversals.each do |credit|
              a(href: billing_path(credit)) { number_to_currency(credit.amount_cents / 100.0) }
              plain " "
            end
            plain "(net #{number_to_currency(@entry.net_cents / 100.0)})"
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
            pre(class: "code-block") { JSON.pretty_generate(@entry.metadata) }
          end
        end
      end
    end
  end
end
