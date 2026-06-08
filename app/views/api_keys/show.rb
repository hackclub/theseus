# frozen_string_literal: true

class Views::APIKeys::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    # Header
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        a(href: api_keys_path, style: "text-decoration: none; color: var(--foreground2);") { "← API Keys" }
        strong(style: "font-size: 1.15em;") { api_key.pretty_name }
        span("is-": "badge", "variant-": api_key.active? ? "green" : "red") do
          api_key.active? ? "Active" : "Revoked"
        end
      end
      span(class: "toolbar-spacer")
    end

    div(class: "show-layout") do
      # Main content
      div(class: "show-main") do
        # Secret Key
        div("box-": "round", style: "margin-bottom: 1lh;") do
          strong { "Secret Key" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh;") do
            row("gap-": "1", "align-": "center") do
              code(data_copy_to_clipboard: api_key.token) { api_key.token }
              button(
                "size-": "small",
                data_copy_to_clipboard: api_key.token,
                aria: { label: "Copy to clipboard" }
              ) { "⎘" }
            end
            p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0.25lh 0 0;") { "Keep this secret. Don't share it with anyone." }
          end
        end

        # Details
        div("box-": "round", style: "margin-bottom: 1lh;") do
          strong { "Details" }
          div("is-": "separator")
          div(class: "detail-grid", style: "margin-top: 0.5lh;") do
            span(class: "detail-label") { "Name" }
            span { api_key.pretty_name }
            span(class: "detail-label") { "Created" }
            span { api_key.created_at.strftime("%b %d, %Y %H:%M") }
            if api_key.revoked?
              span(class: "detail-label") { "Revoked" }
              span(style: "color: var(--red);") { api_key.revoked_at.strftime("%b %d, %Y at %l:%M %p") }
            end
          end
        end

        # Permissions
        div("box-": "round", style: "margin-bottom: 1lh;") do
          strong { "Permissions" }
          div("is-": "separator")
          div(class: "detail-grid", style: "margin-top: 0.5lh;") do
            span(class: "detail-label") { "PII Access" }
            if api_key.pii
              span(style: "color: var(--green);") { "✓ Enabled" }
            else
              span(style: "color: var(--foreground2);") { "✗ Disabled" }
            end

            span(class: "detail-label") { "Impersonation" }
            if api_key.may_impersonate?
              span(style: "color: var(--red);") { "✓ Enabled" }
            else
              span(style: "color: var(--foreground2);") { "✗ Disabled" }
            end
          end
        end
      end

      # Sidebar
      div(class: "show-sidebar") do
        if api_key.active?
          div("box-": "round") do
            strong { "Actions" }
            div("is-": "separator")
            div(style: "margin-top: 0.5lh;") do
              render_revoke_dialog
            end
          end
        else
          div("box-": "round") do
            div(style: "text-align: center; padding: 1lh 0; color: var(--red);") do
              span(style: "font-size: 2em;") { "✗" }
              div(style: "margin-top: 0.5lh;") { strong { "Revoked" } }
            end
          end
        end
      end
    end
  end

  private

  attr_reader :api_key

  def render_revoke_dialog
    dialog(id: "revoke-dialog", "size-": "large", "position-": "center", "container-": "fill") do
      column("box-": "round", "shear-": "top") do
        row("align-": "center between") do
          span("is-": "badge", "variant-": "background0") { "Revoking #{api_key.pretty_name}..." }
          button("variant-": "foreground0", onclick: safe("this.closest('dialog').close()")) { "×" }
        end
        p(style: "color: var(--foreground2); margin: 0 0 1lh;") { "That which thou canst not undo." }
        div("is-": "separator")

        form_with url: revoke_api_key_path(api_key), method: :post, local: true do |f|
          div("box-": "square", class: "tui-banner tui-banner-error", style: "margin: 1lh 0;") do
            plain "⚠ This is irreversible and painful! Are you sure you want to revoke this key? Everything that relies on it will unceremoniously break."
          end

          div("is-": "separator")
          row("gap-": "1", style: "justify-content: flex-end; padding: 1lh 0;") do
            button(onclick: safe("document.getElementById('revoke-dialog').close()")) { "Cancel" }
            button("variant-": "red", type: "submit") { "Do it. Pull the trigger. I can't even stand to look at it anymore." }
          end
        end
      end
    end

    button("variant-": "red", style: "width: 100%;", onclick: safe("document.getElementById('revoke-dialog').showModal()")) { "× Revoke Key" }
  end
end
