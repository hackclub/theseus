# frozen_string_literal: true

class Views::APIKeys::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: api_keys_path, class: "link-muted") { "← API Keys" }
        strong(class: "text-title") { "New API Key" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        section do
          strong { "Details" }
          hr
          div(class: "mt-half") do
            form_with model: api_key, url: api_keys_path, local: true do |f|
              div(class: "mb-1") do
                label(class: "form-field-label") { "Name" }
                input(type: "text", name: "api_key[name]", autofocus: true, class: "w-100")
                p(class: "field-hint") { "Short description (think \"high-seas\")" }
              end

              fieldset(class: "fieldset-reset") do
                legend(class: "fieldset-legend") { "Permissions" }

                label do
                  input(type: "checkbox", name: "api_key[pii]", value: "1")
                  plain " PII Access"
                end
                p(class: "checkbox-hint") { "Should this key be able to read address data? (probably not!)" }

                admin_tool do
                  label do
                    input(type: "checkbox", name: "api_key[may_impersonate]", value: "1")
                    plain " Can Impersonate"
                  end
                  p(class: "checkbox-hint") { "Can this key impersonate other back office users? (don't enable unless needed)" }
                end
              end

              if current_user.billing_profiles.any?
                div(class: "mb-1 mt-1") do
                  label(class: "form-field-label") { "Default Billing Profile" }
                  select(name: "api_key[billing_profile_id]", class: "w-100") do
                    option(value: "") { "None (no billing)" }
                    current_user.billing_profiles.each do |profile|
                      option(value: profile.id) { profile.organization_name }
                    end
                  end
                  p(class: "field-hint") { "Warehouse orders created through this key will bill this organization." }
                end
              end

              button(type: "submit", class: "btn-success w-100") { "🔑 Create API Key" }
            end
          end
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "About API Keys" }
          hr
          div(class: "mt-half text-muted help-text") do
            p { "API keys grant programmatic access to the system." }
            p { "PII access should only be enabled when the integration specifically needs address data." }
          end
        end
      end
    end
  end

  private

  attr_reader :api_key
end
