# frozen_string_literal: true

class Components::Admin::USPS::PaymentAccounts::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(payment_account:)
    @payment_account = payment_account
  end

  def view_template
    if @payment_account.errors.any?
      div(class: "banner banner-alert") do
        plain @payment_account.errors.full_messages.to_sentence
      end
    end

    form_with model: @payment_account, url: form_url, local: true do |f|
      div(class: "form-stack") do
        render Components::Shared::FormField.new(label: "Name", name: "usps_payment_account[name]", value: @payment_account.name)

        # Account type select
        render Components::Shared::FormField.new(label: "Account Type", required: true, input: false) do
          select(name: "usps_payment_account[account_type]", required: true, class: "form-field-input") do
            option(value: "") { "Select type…" }
            ::USPS::PaymentAccount.account_types.each_key do |type|
              if @payment_account.account_type == type
                option(value: type, selected: true) { type }
              else
                option(value: type) { type }
              end
            end
          end
        end

        render Components::Shared::FormField.new(label: "Account Number", name: "usps_payment_account[account_number]", value: @payment_account.account_number,
          hint: "Required for EPS accounts")

        render Components::Shared::FormField.new(label: "Permit Number", name: "usps_payment_account[permit_number]", value: @payment_account.permit_number,
          hint: "Required for PERMIT accounts")

        render Components::Shared::FormField.new(label: "Permit ZIP", name: "usps_payment_account[permit_zip]", value: @payment_account.permit_zip,
          hint: "Required for PERMIT accounts")

        render Components::Shared::FormField.new(label: "Manifest MID", name: "usps_payment_account[manifest_mid]", value: @payment_account.manifest_mid,
          hint: "Falls back to Mailer ID's MID if blank")

        # Mailer ID select
        render Components::Shared::FormField.new(label: "Mailer ID", required: true, input: false) do
          select(name: "usps_payment_account[usps_mailer_id_id]", required: true, class: "form-field-input") do
            option(value: "") { "Select mailer ID…" }
            ::USPS::MailerId.all.each do |mid|
              label_text = mid.name.present? ? "#{mid.name} (#{mid.mid})" : mid.mid
              if @payment_account.usps_mailer_id_id == mid.id
                option(value: mid.id, selected: true) { label_text }
              else
                option(value: mid.id) { label_text }
              end
            end
          end
        end

        # ACH checkbox
        render Components::Shared::FormField.new(label: "ACH", input: false) do
          input(type: "hidden", name: "usps_payment_account[ach]", value: "0")
          label(style: "display:inline-flex;align-items:center;gap:0.5rem;cursor:pointer;") do
            if @payment_account.ach?
              input(type: "checkbox", name: "usps_payment_account[ach]", value: "1", checked: true)
            else
              input(type: "checkbox", name: "usps_payment_account[ach]", value: "1")
            end
            plain "ACH enabled"
          end
        end

        div(style: "padding-top:1rem;") do
          button(type: "submit", class: "btn-success") do
            plain(@payment_account.persisted? ? "Update Payment Account" : "Create Payment Account")
          end
        end
      end
    end
  end

  private

  def form_url
    if @payment_account.persisted?
      admin_usps_payment_account_path(@payment_account)
    else
      admin_usps_payment_accounts_path
    end
  end

end
