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
              span(class: "detail-label") { "Net billed" }
              span { money(entries.live.sum(:amount_cents)) }

              span(class: "detail-label") { "Settled" }
              span { money(entries.settled.sum(:amount_cents)) }

              span(class: "detail-label") { "Pending" }
              pending = entries.pending.sum(:amount_cents)
              if pending != 0
                span(class: "badge badge-warning") { money(pending) }
              else
                span(class: "text-muted") { "$0.00" }
              end

              stuck = profile.hcb_transfers.where(state: [:unknown, :failed]).count
              if stuck > 0
                span(class: "detail-label") { "Transfers needing attention" }
                span(class: "badge badge-danger") { stuck.to_s }
              end
            end
          end
        end
      end
    end

    if helpers.current_user&.admin?
      attention = HCB::Transfer.where(state: [:failed, :unknown]).includes(:billing_profile).order(:created_at)
      if attention.any?
        section(style: "margin-bottom:1.5rem;") do
          h3(style: "margin-top:0;") { "Transfers needing attention" }
          table do
            thead { tr { th { "Created" }; th { "Org" }; th { "Direction" }; th { "HQ org" }; th { "Amount" }; th { "State" }; th { "Attempts" }; th { "Error" }; th { "" } } }
            tbody do
              attention.each do |t|
                tr do
                  td(class: "text-muted") { t.created_at.strftime("%b %d %H:%M") }
                  td { t.billing_profile.organization_name }
                  td { t.direction }
                  td { code { t.hq_organization_id } }
                  td { money(t.amount_cents) }
                  td { transfer_cell(t) }
                  td { "#{t.attempts}#{t.next_attempt_at ? " (next #{t.next_attempt_at.strftime("%H:%M")})" : ""}" }
                  td(class: "text-muted") { t.last_error }
                  td do
                    form(action: retry_transfer_billing_index_path(transfer_id: t.id), method: "post", class: "form-inline",
                         onsubmit: (t.unknown? ? "return confirm('This transfer is UNKNOWN. Only retry if you have checked HCB and it is NOT there. Continue?')" : nil)) do
                      input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
                      button(type: "submit", class: "btn-sm #{t.unknown? ? "btn-danger" : "btn-warning"}") { t.unknown? ? "Force retry" : "Retry now" }
                    end
                  end
                end
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
            th { "Transfer" }
          end
        end
        tbody do
          @ledger_entries.each do |entry|
            tr do
              td(class: "text-muted") { entry.created_at.strftime("%b %d, %Y %H:%M") }
              td do
                span(class: "badge badge-info") { entry.category }
              end
              td(style: "font-weight:600;", class: (entry.credit? ? "text-success" : nil)) { money(entry.amount_cents) }
              td { ledgerable_link(entry) }
              td { entry.billing_profile.organization_name }
              td { state_badge(entry.state) }
              td { transfer_cell(entry.hcb_transfer) }
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
end
