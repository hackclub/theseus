# frozen_string_literal: true

class Views::Billing::Index < Views::Base
  def initialize(ledger_entries:, billing_profiles:)
    @ledger_entries = ledger_entries
    @billing_profiles = billing_profiles
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Billing",
      jumpcode_path: billing_index_path,
    )

    # Summary cards per billing profile
    if @billing_profiles.any?
      div(style: "display:flex;gap:1rem;flex-wrap:wrap;margin-bottom:1.5rem;") do
        @billing_profiles.each do |profile|
          entries = profile.ledger_entries
          section(style: "flex:1;min-width:200px;") do
            strong { profile.organization_name }
            div(class: "detail-grid", style: "margin-top:0.5rem;") do
              span(class: "detail-label") { "Total billed" }
              span { "$#{"%.2f" % (entries.where.not(state: :refunded).sum(:amount_cents) / 100.0)}" }

              span(class: "detail-label") { "Settled" }
              span { "$#{"%.2f" % (entries.settled.sum(:amount_cents) / 100.0)}" }

              span(class: "detail-label") { "Pending" }
              pending = entries.pending.sum(:amount_cents)
              if pending > 0
                span(class: "badge badge-warning") { "$#{"%.2f" % (pending / 100.0)}" }
              else
                span(class: "text-muted") { "$0.00" }
              end

              failed = entries.failed.sum(:amount_cents)
              if failed > 0
                span(class: "detail-label") { "Failed" }
                span(class: "badge badge-danger") { "$#{"%.2f" % (failed / 100.0)}" }
              end
            end
          end
        end
      end
    end

    # Ledger entries table
    if @ledger_entries.any?
      table do
        thead do
          tr do
            th { "Date" }
            th { "Category" }
            th { "Amount" }
            th { "For" }
            th { "Organization" }
            th { "State" }
            th { "HCB Transfer" }
          end
        end
        tbody do
          @ledger_entries.each do |entry|
            tr do
              td(class: "text-muted") { entry.created_at.strftime("%b %d, %Y %H:%M") }
              td do
                span(class: "badge badge-info") { entry.category }
              end
              td(style: "font-weight:600;") { "$#{"%.2f" % entry.amount}" }
              td { ledgerable_link(entry) }
              td { entry.billing_profile.organization_name }
              td { state_badge(entry.state) }
              td do
                if entry.hcb_transfer_id.present?
                  code(class: "text-muted") { entry.hcb_transfer_id.truncate(16) }
                else
                  span(class: "text-muted") { "—" }
                end
              end
            end
          end
        end
      end

      # Pagination
      div(style: "margin-top:1rem;") do
        raw helpers.paginate(@ledger_entries)
      end
    else
      p(class: "text-muted") { "No billing entries yet." }
    end
  end

  private

  def state_badge(state)
    variant = case state
              when "settled" then "badge-success"
              when "pending" then "badge-warning"
              when "failed" then "badge-danger"
              when "refunded" then "badge"
              end
    span(class: "badge #{variant}") { state }
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
end
