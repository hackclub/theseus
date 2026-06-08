# frozen_string_literal: true

class Views::APIKeys::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "page-container--narrow") do
      div(class: "page-header") do
        div do
          div(class: "page-title-group") do
            h1(class: "page-title") { api_key.pretty_name }
            span("is-": "badge", "variant-": api_key.active? ? "green" : "background2") do
              api_key.active? ? "Active" : "Revoked"
            end
          end
          p(class: "page-subtitle") { "Created #{api_key.created_at.strftime('%B %d, %Y')}" }
        end
      end

      div("box-": "round", style: "margin-bottom: 1lh;") do
        h3(style: "margin: 0;") { "Secret Key" }
        div("is-": "separator")
        div(style: "padding: 1lh 1ch;") do
          div(class: "kv-row") do
            code(
              class: "api-key-token",
              data_copy_to_clipboard: api_key.token
            ) { api_key.token }

            button(
              "size-": "small",
              data_copy_to_clipboard: api_key.token,
              aria: { label: "Copy to clipboard" }
            ) { "⎘" }
          end
          p(class: "api-key-secret-hint") { "Keep this secret. Don't share it with anyone." }
        end
      end

      div("box-": "round", style: "margin-bottom: 1lh;") do
        h3(style: "margin: 0;") { "Permissions" }
        div("is-": "separator")
        div do
          pii_color = api_key.pii ? "var(--green)" : "var(--foreground2)"
          div(class: "api-key-perm-row#{api_key.pii ? ' api-key-perm-row--active-success' : ''}") do
            span(class: "fw-semibold", style: "color: #{pii_color};") { api_key.pii ? "✓" : "✗" }
            span(class: "fw-medium") { "PII Access" }
          end
        end
        div("is-": "separator")
        div do
          imp_color = api_key.may_impersonate? ? "var(--red)" : "var(--foreground2)"
          div(class: "api-key-perm-row#{api_key.may_impersonate? ? ' api-key-perm-row--active-danger' : ''}") do
            span(class: "fw-semibold", style: "color: #{imp_color};") { api_key.may_impersonate? ? "✓" : "✗" }
            span(class: "fw-medium") { "Can Impersonate" }
          end
        end
      end

      if api_key.revoked?
        div("box-": "square", class: "tui-banner tui-banner-warning", style: "margin-bottom: 1lh;") do
          strong { "⚠ Revoked on #{api_key.revoked_at.strftime('%B %d, %Y at %l:%M %p')}" }
        end
      end

      div(class: "page-actions") do
        render Components::Shared::BackButton.new(href: api_keys_path)
        if api_key.active?
          render_revoke_dialog
        end
      end
    end
  end

  private

  attr_reader :api_key

  def render_revoke_dialog
    dialog(id: "revoke-dialog", "size-": "large", "position-": "center", "container-": "fill") do
      column( "box-": "round", "shear-": "top") do
        row( "align-": "center between") do
          span("is-": "badge", "variant-": "background0") { "Revoking #{api_key.pretty_name}..." }
          button("size-": "small", "variant-": "foreground0", onclick: safe("this.closest('dialog').close()")) { "×" }
        end
        p(style: "color: var(--foreground2); margin: 0 0 1lh;") { "That which thou canst not undo." }
        div("is-": "separator")

        form_with url: revoke_api_key_path(api_key), method: :post, local: true do |f|
          div("box-": "square", class: "tui-banner tui-banner-error", style: "margin: 1lh 0;") do
            plain "⚠ This is irreversible and painful! Are you sure you want to revoke this key? Everything that relies on it will unceremoniously break."
          end

          div("is-": "separator")
          row( "gap-": "1", style: "justify-content: flex-end; padding: 1lh 0;") do
            button(onclick: safe("document.getElementById('revoke-dialog').close()")) { "Cancel" }
            button("size-": "small", "variant-": "red", type: "submit") { "Do it. Pull the trigger. I can't even stand to look at it anymore." }
          end
        end
      end
    end

    button("size-": "small", "variant-": "red", onclick: safe("document.getElementById('revoke-dialog').showModal()")) { "× Revoke Key" }
  end
end
