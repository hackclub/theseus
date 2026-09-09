# frozen_string_literal: true

class Views::Billing::Index < Views::Base
  include Components::Shared::BillingHelpers

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
      div(class: "flex-wrap-row mb-1h") do
        @billing_profiles.each do |profile|
          entries = profile.ledger_entries
          section(style: "flex:1;min-width:200px") do
            strong { profile.organization_name }
            div(class: "detail-grid mt-half") do
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
      nsf = HCB::Transfer.where("metadata->>'nsf' = 'true'").where(state: [ :failed, :unknown ]).where("metadata->>'abandoned_at' IS NULL").where(id: LedgerEntry.pending.select(:hcb_transfer_id)).includes(:billing_profile).order(:created_at)
      if nsf.any?
        div(class: "banner banner-error mb-1h") do
          strong { "⚠ #{helpers.pluralize(nsf.map(&:billing_profile_id).uniq.size, "organization")} can't pay: " }
          plain nsf.map { |t| "#{t.billing_profile.organization_name} owes #{money(t.amount_cents)} (#{t.attempts}/#{HCB::Transfer::MAX_ATTEMPTS} attempts#{t.gave_up? ? ", gave up" : ""})" }.join("; ")
          plain ". Linked by: #{nsf.map { |t| t.billing_profile.user&.email }.compact.uniq.join(", ")}."
        end
      end

      attention = HCB::Transfer.where(state: [ :failed, :unknown ]).where("metadata->>'abandoned_at' IS NULL").includes(:billing_profile).order(:created_at)

      if attention.any?
        section(class: "mb-1h") do
          h3(class: "mt-0") { "Transfers needing attention" }
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
                  td { "#{t.attempts}#{t.next_attempt_at ? " (next #{t.next_attempt_at.strftime("%H:%M")})" : ""}#{t.metadata["nsf"] ? " · NSF" : ""}" }
                  td(class: "text-muted") { t.last_error }
                  td do
                    next span(class: "text-muted") { "no pending entries" } if t.ledger_entries.pending.none?
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
              td(class: "fw-600#{entry.credit? ? " text-success" : ""}") { money(entry.amount_cents) }
              td { ledgerable_link(entry) }
              td { entry.billing_profile.organization_name }
              td { state_badge(entry.state) }
              td { transfer_cell(entry.hcb_transfer) }
            end
          end
        end
      end

      # Pagination
      div(class: "mt-1") do
        raw helpers.paginate(@ledger_entries)
      end
    else
      p(class: "text-muted") { "No billing entries yet." }
    end
  end


end
