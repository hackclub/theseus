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
        form_field("Name", "usps_payment_account[name]", @payment_account.name)

        # Account type select
        div(style: "margin-bottom:1rem;") do
          label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") do
            plain "Account Type *"
          end
          select(name: "usps_payment_account[account_type]", required: true, style: "width:100%;") do
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

        form_field("Account Number", "usps_payment_account[account_number]", @payment_account.account_number,
          hint: "Required for EPS accounts")

        form_field("Permit Number", "usps_payment_account[permit_number]", @payment_account.permit_number,
          hint: "Required for PERMIT accounts")

        form_field("Permit ZIP", "usps_payment_account[permit_zip]", @payment_account.permit_zip,
          hint: "Required for PERMIT accounts")

        form_field("Manifest MID", "usps_payment_account[manifest_mid]", @payment_account.manifest_mid,
          hint: "Falls back to Mailer ID's MID if blank")

        # Mailer ID select
        div(style: "margin-bottom:1rem;") do
          label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") do
            plain "Mailer ID *"
          end
          select(name: "usps_payment_account[usps_mailer_id_id]", required: true, style: "width:100%;") do
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
        div(style: "margin-bottom:1rem;") do
          label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "ACH" }
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

  def form_field(label_text, name, value, required: false, type: "text", hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") do
        plain label_text
        plain " *" if required
      end
      input(type: type, name: name, value: value, required: required, style: "width:100%;")
      if hint
        small(class: "text-muted") { hint }
      end
    end
  end
end
