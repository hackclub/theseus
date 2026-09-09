# frozen_string_literal: true

class Views::APIKeys::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: api_keys_path, class: "link-muted") { "← API Keys" }
        strong(class: "text-title") { api_key.pretty_name }
        span(class: api_key.active? ? "badge badge-success" : "badge badge-danger") do
          api_key.active? ? "Active" : "Revoked"
        end
      end
      span(class: "spacer")
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        secret_key_box
        details_box
        permissions_box
      end

      div(class: "show-sidebar") do
        if api_key.active?
          section do
            strong { "Actions" }
            hr
            div(class: "mt-half") do
              render_revoke_dialog
            end
          end
        else
          section do
            div(class: "revoked-panel") do
              span(class: "revoked-icon") { "✗" }
              div(class: "mt-half") { strong { "Revoked" } }
            end
          end
        end
      end
    end
  end

  private

  attr_reader :api_key

  def secret_key_box
    section(class: "mb-1") do
      strong { "Secret Key" }
      hr
      div(class: "mt-half") do
        div(class: "flex-row") do
          code(data_copy_to_clipboard: api_key.token) { api_key.token }
          button(
            class: "btn-sm",
            data_copy_to_clipboard: api_key.token,
            aria: { label: "Copy to clipboard" }
          ) { "⎘" }
        end
        p(class: "field-hint") { "Keep this secret. Don't share it with anyone." }
      end
    end
  end

  def details_box
    section(class: "mb-1") do
      strong { "Details" }
      hr
      div(class: "detail-grid mt-half") do
        span(class: "detail-label") { "Name" }
        span { api_key.pretty_name }
        span(class: "detail-label") { "Created" }
        span { api_key.created_at.strftime("%b %d, %Y %H:%M") }
        if api_key.revoked?
          span(class: "detail-label") { "Revoked" }
          span(class: "text-danger") { api_key.revoked_at.strftime("%b %d, %Y %H:%M") }
        end
        span(class: "detail-label") { "Billing Profile" }
        if api_key.billing_profile.present?
          span do
            a(href: hcb_payment_account_path(api_key.billing_profile), class: "no-underline") do
              plain api_key.billing_profile.organization_name
            end
            plain " "
            code(class: "text-sm text-muted") { api_key.billing_profile.public_id }
          end
        else
          span(class: "text-muted") { "None" }
        end
      end
    end
  end

  def permissions_box
    section(class: "mb-1") do
      strong { "Permissions" }
      hr
      div(class: "detail-grid mt-half") do
        span(class: "detail-label") { "PII Access" }
        if api_key.pii
          span(class: "text-success") { "✓ Enabled" }
        else
          span(class: "text-muted") { "✗ Disabled" }
        end

        span(class: "detail-label") { "Impersonation" }
        if api_key.may_impersonate?
          span(class: "text-danger") { "✓ Enabled" }
        else
          span(class: "text-muted") { "✗ Disabled" }
        end
      end
    end
  end

  def render_revoke_dialog
    dialog(id: "revoke-dialog") do
      div(class: "dialog-body") do
        div(class: "stat-total-row") do
          span(class: "badge") { "Revoking #{api_key.pretty_name}..." }
          button(onclick: safe("this.closest('dialog').close()")) { "×" }
        end
        p(class: "text-muted dialog-subtitle") { "That which thou canst not undo." }
        hr

        form_with url: revoke_api_key_path(api_key), method: :post, local: true do |f|
          div(class: "banner banner-error mt-1 mb-1") do
            plain "⚠ This is irreversible and painful! Are you sure you want to revoke this key? Everything that relies on it will unceremoniously break."
          end

          hr
          div(class: "dialog-footer") do
            button(onclick: safe("document.getElementById('revoke-dialog').close()")) { "Cancel" }
            button(class: "btn-danger", type: "submit") { "Do it. Pull the trigger. I can't even stand to look at it anymore." }
          end
        end
      end
    end

    button(class: "btn-danger w-100", onclick: safe("document.getElementById('revoke-dialog').showModal()")) { "× Revoke Key" }
  end
end
