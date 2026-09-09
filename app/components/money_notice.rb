# frozen_string_literal: true

class Components::MoneyNotice < Components::Base
  GLYPH = "$"

  def initialize(lines:, profiles:, field: "hcb_payment_account_id", selected: nil, proceed: nil, cancel_href: nil,
                 refund: false, locked: false, unbilled: false, id: "billing-consent", refresh_url: nil, connect_href: nil, balances: nil)
    @quote = ::Billing::Quote.new(lines)
    @profiles = Array(profiles)
    @field = field
    @selected = selected || @profiles.first
    @proceed = proceed
    @cancel_href = cancel_href
    @refund = refund
    @locked = locked || @profiles.size == 1 && @proceed.nil?
    @id = id
    @refresh_url = refresh_url
    @connect_href = connect_href
    @balances = balances
    @unbilled = unbilled
  end

  def view_template
    div(id: @id, class: classes, data: { money_notice: true, refresh_url: @refresh_url }) do
      head
      div(class: "money-notice__body") do
        if @profiles.empty?
          @unbilled ? not_billed : no_profiles
        else
          payer
          lines
          balances unless @refund
        end
      end
      foot if @proceed && (@profiles.any? || @unbilled)
      script_once
    end
  end

  private

  def classes
    kind = if @refund then "money-notice--credit" elsif @proceed.nil? then "money-notice--preview" end
    [ "money-notice", kind ].compact.join(" ")
  end

  def head
    div(class: "money-notice__head") do
      span(class: "money-notice__glyph") { GLYPH }
      span { title }
      span(class: "money-notice__sub") { subtitle } if subtitle
    end
  end

  def title
    return "Refund" if @refund
    @proceed ? "Charge" : "Cost estimate"
  end

  def subtitle
    return nil if @proceed.nil?
    return "credit back to the org" if @refund
    "pay via HCB"
  end

  def no_profiles
    p(class: "money-notice__none") do
      plain "No HCB organization is linked to pay for this. "
      a(href: @connect_href || new_hcb_oauth_connection_path) { "Connect your HCB account" }
      plain " first."
    end
  end

  def not_billed
    p(class: "money-notice__none") { "No HCB organization is attached, so this will not be billed." }
  end

  def payer
    div(class: "money-notice__payer") do
      plain "Your HCB account"
      if @locked || @profiles.size == 1
        strong(data: { org_name: true }) { @selected.organization_name }
        input(type: "hidden", name: @field, value: @selected.id) if @field && !@locked
      else
        select(name: @field, required: true, data: { money_select: true }) do
          @profiles.each do |profile|
            option(value: profile.id, selected: profile.id == @selected&.id) { profile.organization_name }
          end
        end
      end
      plain(@refund ? "will be credited" : "will be billed")
    end
  end

  def lines
    table(class: "money-notice__lines") do
      tbody do
        @quote.lines.each { |line| line_row(line) }
      end
      if @quote.lines.size > 1 || @quote.later?
        tfoot do
          tr do
            td(class: "money-notice__amt") { money(@quote.now_cents) }
            td(class: "money-notice__label") { @refund ? "total credit" : "due now" }
            td(class: "money-notice__when") { "" }
          end
          if @quote.later?
            tr do
              td(class: "money-notice__amt money-notice__amt--est") { later_total }
              td(class: "money-notice__label") { "billed later, at cost" }
              td(class: "money-notice__when") { "" }
            end
          end
        end
      end
    end
  end

  def line_row(line)
    tr do
      td(class: "money-notice__amt#{line.known? ? "" : " money-notice__amt--est"}") { amount(line) }
      td(class: "money-notice__label") { line.label }
      td(class: "money-notice__when") { tag_for(line) }
    end
  end

  def amount(line)
    line.known? ? money(line.amount_cents) : "at cost"
  end

  def later_total
    @quote.later_cents.zero? ? "at cost" : "~#{money(@quote.later_cents)}"
  end

  def tag_for(line)
    if @refund
      span(class: "money-notice__tag money-notice__tag--back") { "back" }
    elsif line.now?
      span(class: "money-notice__tag") { "now" }
    else
      span(class: "money-notice__tag money-notice__tag--later") { "later" }
    end
  end

  def balances
    @profiles.each do |profile|
      cents = @balances ? @balances[profile.id] : ::Billing::Balance.cents_for(profile)
      level = @quote.assess(cents)
      div(class: "money-notice__balance money-notice__balance--#{level}", hidden: profile.id != @selected&.id, data: { balance_for: profile.id }) do
        balance_text(profile, cents, level)
      end
    end
  end

  def balance_text(profile, cents, level)
    org = profile.organization_name
    case level
    when :ok
      plain "✓ #{org} has #{money(cents)}. Covered."
    when :insufficient
      plain "✕ #{org} has #{money(cents)}, which does not cover the #{money(@quote.now_cents)} due now. This charge will fail. Top up first."
    when :low
      plain "⚠ #{org} has #{money(cents)}. "
      plain(@quote.now_cents.positive? ? "That covers today, but it's thin" : "That's thin")
      plain(@quote.later? ? " for what's billed later. " : ". ")
      plain "Top up before then, or we'll come round with crowbars and a keen interest in your kneecaps."
    else
      plain "? Couldn't check #{org}'s balance right now. Make sure it's funded before you proceed."
    end
  end

  def foot
    div(class: "money-notice__foot") do
      span(class: "spacer")
      a(href: @cancel_href) { "Cancel" } if @cancel_href
      button(type: "submit", class: "btn-money", data: { disable_with: "Working…" }) do
        span { @proceed }
        span(class: "btn-money__amt") { @profiles.empty? ? "unbilled" : (@refund || @quote.now_cents.positive? ? money(@quote.now_cents) : "later") }
      end
    end
  end

  def money(cents) = number_to_currency(cents.to_i.abs / 100.0)

  def script_once
    script(data: { money_notice_script: true }) do
      raw(<<~JS.html_safe)
        (function(){
          if (window.__moneyNoticeBound) return; window.__moneyNoticeBound = true;
          document.addEventListener('change', function(e){
            var sel = e.target;
            if (!sel.matches || !sel.matches('[data-money-select]')) return;
            var box = sel.closest('[data-money-notice]');
            box.querySelectorAll('[data-balance-for]').forEach(function(el){ el.hidden = el.dataset.balanceFor !== sel.value; });
          });
        })();
      JS
    end
  end
end
