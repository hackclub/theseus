# frozen_string_literal: true

class Components::BillingInfo < Components::Base
  def initialize(ledger_entries:)
    @entries = ledger_entries.respond_to?(:load) ? ledger_entries.includes(:hcb_transfer, :billing_profile).load : Array(ledger_entries)
  end

  def view_template
    return if @entries.empty?

    div(class: "money-notice") do
      div(class: "money-notice__head") do
        svg(viewBox: "0 0 16 16", class: "money-notice__icon", fill: "currentColor", aria_hidden: "true") { raw(icon_svg("bank")) }
        span { "Billing" }
      end
      div(class: "money-notice__body") do
        entries_table
        transfers_links
      end
    end
  end

  private

  def live_entries = @entries.reject(&:voided?)

  def entries_table
    table(class: "money-notice__lines") do
      tbody do
        @entries.each do |entry|
          tr(class: entry.voided? ? "billing-info__voided" : nil) do
            td(class: "money-notice__label") { plain entry.category }
            td(class: "money-notice__amt") do
              span(class: "money-notice__readout#{entry.credit? ? " money-notice__readout--est" : ""}") do
                plain number_to_currency(entry.amount_cents / 100.0)
              end
            end
            td(class: "money-notice__label") { span(class: "text-muted") { entry.state } }
            td do
              a(href: billing_path(entry)) { "LE##{entry.id}" }
            end
          end
        end
      end
      if @entries.size > 1
        tfoot do
          tr do
            td(class: "money-notice__label") { "" }
            td(class: "money-notice__amt") do
              span(class: "money-notice__readout") { number_to_currency(live_entries.sum(&:amount_cents) / 100.0) }
            end
            td(class: "money-notice__label") { "net" }
            td { "" }
          end
        end
      end
    end
  end

  def transfers_links
    transfers = @entries.filter_map(&:hcb_transfer).uniq
    return if transfers.empty?

    div(class: "billing-info__transfers") do
      transfers.each do |t|
        span(class: "text-muted") { t.state }
        a(href: transfer_show_billing_index_path(key: t.idempotency_key)) do
          code { t.remote_id || t.idempotency_key }
        end
        if t.remote_id.present?
          a(href: "https://hcb.hackclub.com/transactions/#{t.remote_id}", target: "_blank") { "↗ HCB" }
        end
      end
    end
  end
end
