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
            render Primer::Beta::Label.new(scheme: api_key.active? ? :success : :secondary) do
              api_key.active? ? "Active" : "Revoked"
            end
          end
          p(class: "page-subtitle") { "Created #{api_key.created_at.strftime('%B %d, %Y')}" }
        end
      end

      render Primer::Beta::BorderBox.new(mb: 3) do |box|
        box.with_header { "Secret Key" }
        box.with_body do
          div(class: "kv-row") do
            code(
              class: "api-key-token",
              data_copy_to_clipboard: api_key.token
            ) { api_key.token }

            render Primer::Beta::IconButton.new(
              icon: :copy,
              aria: { label: "Copy to clipboard" },
              data_copy_to_clipboard: api_key.token
            )
          end
          p(class: "api-key-secret-hint") { "Keep this secret. Don't share it with anyone." }
        end
      end

      render Primer::Beta::BorderBox.new(mb: 3) do |box|
        box.with_header { "Permissions" }
        box.with_row do
          pii_color = api_key.pii ? "var(--fgColor-success)" : "var(--fgColor-muted)"
          div(class: "api-key-perm-row#{api_key.pii ? ' api-key-perm-row--active-success' : ''}") do
            span(class: "fw-semibold", style: "color: #{pii_color};") { api_key.pii ? "✓" : "✗" }
            span(class: "fw-medium") { "PII Access" }
          end
        end
        box.with_row do
          imp_color = api_key.may_impersonate? ? "var(--fgColor-danger)" : "var(--fgColor-muted)"
          div(class: "api-key-perm-row#{api_key.may_impersonate? ? ' api-key-perm-row--active-danger' : ''}") do
            span(class: "fw-semibold", style: "color: #{imp_color};") { api_key.may_impersonate? ? "✓" : "✗" }
            span(class: "fw-medium") { "Can Impersonate" }
          end
        end
      end

      if api_key.revoked?
        render Primer::Beta::Flash.new(scheme: :warning, mb: 3) do
          strong { "Revoked on #{api_key.revoked_at.strftime('%B %d, %Y at %l:%M %p')}" }
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
    render Primer::Alpha::Dialog.new(
      title: "Revoking #{api_key.pretty_name}...",
      subtitle: "That which thou canst not undo.",
      size: :large,
      id: "revoke-dialog"
    ) do |dialog|
      dialog.with_show_button(scheme: :danger) do |btn|
        btn.with_leading_visual_icon(icon: :x)
        plain "Revoke Key"
      end

      form_with url: revoke_api_key_path(api_key), method: :post, local: true do |f|
        render(Primer::Alpha::Dialog::Body.new) do
          render(Primer::Alpha::Banner.new(icon: :alert, scheme: :danger, description: "Are you sure you want to revoke this key? Everything that relies on it will unceremoniously break.")) { "This is irreversible and painful!" }
        end

        render(Primer::Alpha::Dialog::Footer.new(show_divider: true)) do
          render(Primer::Beta::Button.new(data: { "close-dialog-id": "revoke-dialog" })) { "Cancel" }
          render(Primer::Beta::Button.new(scheme: :danger, type: :submit)) { "Do it. Pull the trigger. I can't even stand to look at it anymore." }
        end
      end
    end
  end
end
