# frozen_string_literal: true

class Views::APIKeys::New < Views::Base
  include Phlex::Rails::Helpers::FormWith
  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    # Header
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        a(href: api_keys_path, style: "text-decoration: none; color: var(--foreground2);") { "← API Keys" }
        strong(style: "font-size: 1.15em;") { "New API Key" }
      end
      span(class: "toolbar-spacer")
    end

    div(class: "show-layout") do
      # Form
      div(class: "show-main") do
        div("box-": "round") do
          strong { "Details" }
          div("is-": "separator")
          div(style: "padding: 1lh 1ch;") do
            form_with model: api_key, url: api_keys_path, local: true do |f|
              div(style: "margin-bottom: 1lh;") do
                label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Name" }
                input(type: "text", name: "api_key[name]", autofocus: true, style: "width: 100%;")
                p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0.25lh 0 0;") { "Short description (think \"high-seas\")" }
              end

              fieldset(class: "fieldset-reset") do
                legend(class: "fieldset-legend") { "Permissions" }

                label do
                  input(type: "checkbox", name: "api_key[pii]", value: "1")
                  plain " PII Access"
                end
                p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0.25lh 0 1lh 2ch;") { "Should this key be able to read address data? (probably not!)" }

                admin_tool do
                  label do
                    input(type: "checkbox", name: "api_key[may_impersonate]", value: "1")
                    plain " Can Impersonate"
                  end
                  p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0.25lh 0 1lh 2ch;") { "Can this key impersonate other back office users? (don't enable unless needed)" }
                end
              end

              button(type: "submit", "variant-": "green", style: "width: 100%;") { "🔑 Create API Key" }
            end
          end
        end
      end

      # Sidebar info
      div(class: "show-sidebar") do
        div("box-": "round") do
          strong { "About API Keys" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh; color: var(--foreground2); font-size: 0.9em;") do
            p(style: "margin: 0 0 0.5lh;") { "API keys grant programmatic access to the system." }
            p(style: "margin: 0;") { "PII access should only be enabled when the integration specifically needs address data." }
          end
        end
      end
    end
  end

  private

  attr_reader :api_key
end
