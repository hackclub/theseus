# frozen_string_literal: true

class Views::Billing::Index < Views::Base
  include Components::Shared::BillingHelpers

  def initialize(ledger_entries:, billing_profiles:, show_all_profiles: false, active_filters: {})
    @ledger_entries = ledger_entries
    @billing_profiles = billing_profiles
    @show_all_profiles = show_all_profiles
    @active_filters = active_filters
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Billing",
      jumpcode_path: billing_index_path,
    )

    if helpers.current_user&.admin?
      nsf_banner
      transfers_needing_attention
    end

    billing_profiles_table
    ledger_entries_table
  end

  private

  # ── NSF banner ──────────────────────────────────────────

  def nsf_banner
    nsf = HCB::Transfer.where("metadata->>'nsf' = 'true'")
      .where(state: [ :failed, :unknown ])
      .where("metadata->>'abandoned_at' IS NULL")
      .where(id: LedgerEntry.pending.select(:hcb_transfer_id))
      .includes(:billing_profile).order(:created_at)
    return unless nsf.any?

    div(class: "banner banner-error mb-1h") do
      strong { "⚠ #{helpers.pluralize(nsf.map(&:billing_profile_id).uniq.size, "organization")} can't pay: " }
      plain nsf.map { |t|
        "#{t.billing_profile.organization_name} owes #{number_to_currency(t.amount_cents / 100.0)} (#{t.attempts}/#{HCB::Transfer::MAX_ATTEMPTS} attempts#{t.gave_up? ? ", gave up" : ""})"
      }.join("; ")
      plain ". Linked by: #{nsf.map { |t| t.billing_profile.user&.email }.compact.uniq.join(", ")}."
    end
  end

  # ── Transfers needing attention ─────────────────────────

  def transfers_needing_attention
    attention = HCB::Transfer.where(state: [ :failed, :unknown ])
      .where("metadata->>'abandoned_at' IS NULL")
      .includes(:billing_profile).order(:created_at)
    return unless attention.any?

    section(class: "mb-1h") do
      h3(class: "mt-0") { "Transfers needing attention (#{attention.size})" }
      table do
        thead do
          tr do
            th { "Created" }
            th { "Org" }
            th { "Direction" }
            th { "HQ org" }
            th { "Amount" }
            th { "State" }
            th { "Attempts" }
            th { "Error" }
            th { "" }
          end
        end
        tbody do
          attention.each { |t| transfer_row(t) }
        end
      end
    end
  end

  def transfer_row(t)
    tr do
      td(class: "text-muted") { t.created_at.strftime("%b %d %H:%M") }
      td { t.billing_profile.organization_name }
      td { t.direction }
      td { code { t.hq_organization_id } }
      td { number_to_currency(t.amount_cents / 100.0) }
      td { transfer_cell(t) }
      td { "#{t.attempts}#{t.next_attempt_at ? " (next #{t.next_attempt_at.strftime("%H:%M")})" : ""}#{t.metadata["nsf"] ? " · NSF" : ""}" }
      td(class: "text-muted") { t.last_error }
      td { retry_button(t) }
    end
  end

  def retry_button(t)
    return span(class: "text-muted") { "no pending entries" } if t.ledger_entries.pending.none?

    form(action: retry_transfer_billing_index_path(transfer_id: t.id), method: "post", class: "form-inline") do
      input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
      if t.unknown?
        input(type: "hidden", name: "force", value: "1")
        button(type: "submit", class: "btn-sm btn-danger", data: { turbo_confirm: force_retry_confirm(t) }) { "Force retry (may double charge)" }
      else
        button(type: "submit", class: "btn-sm btn-warning") { "Retry now" }
      end
    end
  end

  # ── Billing profiles ───────────────────────────────────

  def billing_profiles_table
    return unless @billing_profiles.any?

    active = @billing_profiles.select { |p| profile_has_activity?(p) }
    inactive_count = @billing_profiles.size - active.size
    profiles_to_show = @show_all_profiles ? @billing_profiles.sort_by { |p| p.organization_name.downcase } : active.sort_by { |p| [ -p.hcb_transfers.where(state: [ :unknown, :failed ]).count, p.organization_name.downcase ] }

    section(class: "mb-1h") do
      div(class: "toolbar mb-half") do
        strong { "Billing Profiles" }
        span(class: "text-muted") { "(#{active.size} active of #{@billing_profiles.size})" }
        span(class: "spacer")
        if inactive_count > 0
          if @show_all_profiles
            a(href: billing_index_path, class: "btn-sm") { "Hide empty" }
          else
            a(href: billing_index_path(show_all: 1), class: "btn-sm") { "Show all #{@billing_profiles.size}" }
          end
        end
      end

      table do
        thead do
          tr do
            th { "Organization" }
            th { "User" }
            th(class: "text-right") { "Net billed" }
            th(class: "text-right") { "Settled" }
            th(class: "text-right") { "Pending" }
            th(class: "text-right") { "Stuck" }
          end
        end
        tbody do
          profiles_to_show.each { |p| profile_row(p) }
        end
      end
    end
  end

  def profile_row(profile)
    entries = profile.ledger_entries
    net = entries.live.sum(:amount_cents)
    settled = entries.settled.sum(:amount_cents)
    pending = entries.pending.sum(:amount_cents)
    stuck = profile.hcb_transfers.where(state: [ :unknown, :failed ]).count

    tr do
      td { strong { profile.organization_name } }
      td(class: "text-muted") { profile.user&.email&.split("@")&.first || "—" }
      td(class: "text-right") { money(net) }
      td(class: "text-right") { money(settled) }
      td(class: "text-right") do
        if pending != 0
          span(class: "badge badge-warning") { money(pending) }
        else
          span(class: "text-muted") { "$0.00" }
        end
      end
      td(class: "text-right") do
        if stuck > 0
          span(class: "badge badge-danger") { stuck.to_s }
        else
          span(class: "text-muted") { "—" }
        end
      end
    end
  end

  def profile_has_activity?(profile)
    profile.ledger_entries.any? || profile.hcb_transfers.where(state: [ :unknown, :failed ]).any?
  end

  # ── Ledger entries ─────────────────────────────────────

  def ledger_entries_table
    section do
      div(class: "toolbar mb-half") do
        strong { "Ledger Entries" }
        span(class: "spacer")
        filter_pills
      end

      if @ledger_entries.any?
        table do
          thead do
            tr do
              th { "" }
              th { "Date" }
              th { "Category" }
              th(class: "text-right") { "Amount" }
              th { "For" }
              th { "Organization" }
              th { "State" }
              th { "Transfer" }
            end
          end
          tbody do
            @ledger_entries.each do |entry|
              tr do
                td(class: "text-muted") { a(href: billing_path(entry), class: "no-underline text-muted") { "LE##{entry.id}" } }
                td(class: "text-muted") { entry.created_at.strftime("%b %d, %Y %H:%M") }
                td { span(class: "badge badge-info") { entry.category } }
                td(class: "text-right fw-600#{entry.credit? ? " text-success" : ""}") { number_to_currency(entry.amount_cents / 100.0) }
                td { ledgerable_link(entry) }
                td { entry.billing_profile.organization_name }
                td { state_badge(entry.state) }
                td { transfer_cell(entry.hcb_transfer) }
              end
            end
          end
        end

        div(class: "mt-1") { raw helpers.paginate(@ledger_entries) }
      else
        p(class: "text-muted") { "No billing entries match." }
      end
    end
  end

  def filter_pills
    categories = %w[labor postage contents indicia]
    states = %w[pending settled voided]

    div(class: "kbar-row") do
      categories.each do |cat|
        active = @active_filters[:category] == cat
        cls = active ? "badge badge-info" : "badge"
        href = active ? billing_index_path(state: @active_filters[:state]) : billing_index_path(category: cat, state: @active_filters[:state])
        a(href: href, class: "#{cls} no-underline") { cat }
      end
      span(class: "text-muted") { "|" }
      states.each do |st|
        active = @active_filters[:state] == st
        cls = active ? "badge badge-info" : "badge"
        href = active ? billing_index_path(category: @active_filters[:category]) : billing_index_path(state: st, category: @active_filters[:category])
        a(href: href, class: "#{cls} no-underline") { st }
      end
      if @active_filters[:category].present? || @active_filters[:state].present?
        a(href: billing_index_path, class: "text-muted no-underline") { "× clear" }
      end
    end
  end

  # ── Helpers ────────────────────────────────────────────

  def money(cents)
    number_to_currency(cents / 100.0)
  end

  def force_retry_confirm(transfer)
    "This transfer is UNKNOWN: it may ALREADY have landed on HCB. " \
    "HCB cannot de-duplicate it, so retrying can charge " \
    "#{transfer.billing_profile.organization_name} #{number_to_currency(transfer.amount_cents / 100.0)} a second time. " \
    "Only continue if you have checked HCB by hand and this transfer is NOT there."
  end
end
