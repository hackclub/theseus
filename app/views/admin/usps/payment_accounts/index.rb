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
      div(class: "empty-state-lg") do
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
            th(class: "text-right") { "" }
          end
        end
        tbody do
          @payment_accounts.each do |account|
            tr do
              td do
                a(href: admin_usps_payment_account_path(account), class: "link-strong") { account.name }
              end
              td { type_badge(account) }
              td(class: "text-muted") { mailer_id_label(account) }
              td { ach_badge(account) }
              td(class: "actions-cell") do
                a(href: edit_admin_usps_payment_account_path(account), class: "icon-link") { "✎" }
                button_to "✕", admin_usps_payment_account_path(account), method: :delete, form: { class: "form-inline" }, class: "btn-link-danger", onclick: "return confirm('Delete this payment account?')"
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
