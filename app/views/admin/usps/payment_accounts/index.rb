# frozen_string_literal: true

class Views::Admin::USPS::PaymentAccounts::Index < Views::Base
  def initialize(payment_accounts:)
    @payment_accounts = payment_accounts
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Payment Accounts",
      jumpcode_path: admin_usps_payment_accounts_path,
      action_href: new_admin_usps_payment_account_path,
      action_label: "+ New Payment Account"
    )

    if @payment_accounts.empty?
      div(style: "text-align:center;padding:3rem 1rem;") do
        p(class: "text-muted") { "No payment accounts yet." }
        a(href: new_admin_usps_payment_account_path, class: "btn-success") { "+ New Payment Account" }
      end
    else
      table do
        thead do
          tr do
            th { "Name" }
            th { "Type" }
            th { "Mailer ID" }
            th { "ACH" }
            th(style: "text-align: right;") { "" }
          end
        end
        tbody do
          @payment_accounts.each do |account|
            tr do
              td do
                a(href: admin_usps_payment_account_path(account), style: "text-decoration:none;font-weight:600;") { account.name }
              end
              td { type_badge(account) }
              td(class: "text-muted") { mailer_id_label(account) }
              td { ach_badge(account) }
              td(style: "text-align:right;white-space:nowrap;") do
                a(href: edit_admin_usps_payment_account_path(account), style: "color:GrayText;margin-right:0.5rem;") { "✎" }
                button_to "✕", admin_usps_payment_account_path(account), method: :delete, form: { style: "display:inline;" }, style: "background:none;border:none;color:var(--red);cursor:pointer;font:inherit;padding:0;", onclick: "return confirm('Delete this payment account?')"
              end
            end
          end
        end
      end
    end
  end

  private

  def type_badge(account)
    case account.account_type
    when "EPS"
      span(class: "badge badge-info") { "EPS" }
    when "PERMIT"
      span(class: "badge badge-success") { "PERMIT" }
    else
      span(class: "badge") { account.account_type.to_s }
    end
  end

  def ach_badge(account)
    if account.ach?
      span(class: "badge badge-success") { "ACH" }
    else
      span(class: "badge") { "No" }
    end
  end

  def mailer_id_label(account)
    mid = account.usps_mailer_id
    mid.name.present? ? "#{mid.name} (#{mid.mid})" : mid.mid
  end
end
