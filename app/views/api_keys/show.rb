# frozen_string_literal: true

class Views::APIKeys::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: api_keys_path, style: "text-decoration: none; color: GrayText;") { "← API Keys" }
        strong(style: "font-size: 1.15em;") { api_key.pretty_name }
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
            div(style: "margin-top: 0.5rem;") do
              render_revoke_dialog
            end
          end
        else
          section do
            div(style: "text-align: center; padding: 1rem 0; color: var(--red);") do
              span(style: "font-size: 2em;") { "✗" }
              div(style: "margin-top: 0.5rem;") { strong { "Revoked" } }
            end
          end
        end
      end
    end
  end

  private

  attr_reader :api_key

  def secret_key_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Secret Key" }
      hr
      div(style: "margin-top: 0.5rem;") do
        div(style: "display:flex;align-items:center;gap:0.5rem") do
          code(data_copy_to_clipboard: api_key.token) { api_key.token }
          button(
            class: "btn-sm",
            data_copy_to_clipboard: api_key.token,
            aria: { label: "Copy to clipboard" }
          ) { "⎘" }
        end
        p(style: "color: GrayText; font-size: 0.85em; margin: 0.25rem 0 0;") { "Keep this secret. Don't share it with anyone." }
      end
    end
  end

  def details_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Details" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "Name" }
        span { api_key.pretty_name }
        span(class: "detail-label") { "Created" }
        span { api_key.created_at.strftime("%b %d, %Y %H:%M") }
        if api_key.revoked?
          span(class: "detail-label") { "Revoked" }
          span(style: "color: var(--red);") { api_key.revoked_at.strftime("%b %d, %Y %H:%M") }
        end
      end
    end
  end

  def permissions_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Permissions" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "PII Access" }
        if api_key.pii
          span(style: "color: var(--green);") { "✓ Enabled" }
        else
          span(class: "text-muted") { "✗ Disabled" }
        end

        span(class: "detail-label") { "Impersonation" }
        if api_key.may_impersonate?
          span(style: "color: var(--red);") { "✓ Enabled" }
        else
          span(class: "text-muted") { "✗ Disabled" }
        end
      end
    end
  end

  def render_revoke_dialog
    dialog(id: "revoke-dialog") do
      div(style: "padding: 1rem;") do
        div(style: "display:flex;align-items:center;justify-content:space-between") do
          span(class: "badge") { "Revoking #{api_key.pretty_name}..." }
          button(onclick: safe("this.closest('dialog').close()")) { "×" }
        end
        p(class: "text-muted", style: "margin: 0 0 1rem;") { "That which thou canst not undo." }
        hr

        form_with url: revoke_api_key_path(api_key), method: :post, local: true do |f|
          div(class: "banner banner-error", style: "margin: 1rem 0;") do
            plain "⚠ This is irreversible and painful! Are you sure you want to revoke this key? Everything that relies on it will unceremoniously break."
          end

          hr
          div(style: "display:flex;gap:0.5rem;justify-content: flex-end; padding: 1rem 0;") do
            button(onclick: safe("document.getElementById('revoke-dialog').close()")) { "Cancel" }
            button(class: "btn-danger", type: "submit") { "Do it. Pull the trigger. I can't even stand to look at it anymore." }
          end
        end
      end
    end

    button(class: "btn-danger", style: "width: 100%;", onclick: safe("document.getElementById('revoke-dialog').showModal()")) { "× Revoke Key" }
  end
end
