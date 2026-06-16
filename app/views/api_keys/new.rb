# frozen_string_literal: true

class Views::APIKeys::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: api_keys_path, style: "text-decoration: none; color: GrayText;") { "← API Keys" }
        strong(style: "font-size: 1.15em;") { "New API Key" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        section do
          strong { "Details" }
          hr
          div(style: "margin-top: 0.5rem;") do
            form_with model: api_key, url: api_keys_path, local: true do |f|
              div(style: "margin-bottom: 1rem;") do
                label(style: "display: block; color: GrayText; margin-bottom: 0.25rem;") { "Name" }
                input(type: "text", name: "api_key[name]", autofocus: true, style: "width: 100%;")
                p(style: "color: GrayText; font-size: 0.85em; margin: 0.25rem 0 0;") { "Short description (think \"high-seas\")" }
              end

              fieldset(class: "fieldset-reset") do
                legend(class: "fieldset-legend") { "Permissions" }

                label do
                  input(type: "checkbox", name: "api_key[pii]", value: "1")
                  plain " PII Access"
                end
                p(style: "color: GrayText; font-size: 0.85em; margin: 0.25rem 0 1rem 1rem;") { "Should this key be able to read address data? (probably not!)" }

                admin_tool do
                  label do
                    input(type: "checkbox", name: "api_key[may_impersonate]", value: "1")
                    plain " Can Impersonate"
                  end
                  p(style: "color: GrayText; font-size: 0.85em; margin: 0.25rem 0 1rem 1rem;") { "Can this key impersonate other back office users? (don't enable unless needed)" }
                end
              end

              button(type: "submit", class: "btn-success", style: "width: 100%;") { "🔑 Create API Key" }
            end
          end
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "About API Keys" }
          hr
          div(style: "margin-top: 0.5rem; color: GrayText;") do
            p(style: "margin: 0 0 0.5rem;") { "API keys grant programmatic access to the system." }
            p(style: "margin: 0;") { "PII access should only be enabled when the integration specifically needs address data." }
          end
        end
      end
    end
  end

  private

  attr_reader :api_key
end
