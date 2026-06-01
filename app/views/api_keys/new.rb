# frozen_string_literal: true

class Views::APIKeys::New < Views::Base
  include Phlex::Rails::Helpers::FormWith
  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "page-container--xs") do
      h1(class: "page-title content-section") { "New API Key" }

      render Primer::Beta::BorderBox.new(mb: 4) do |box|
        box.with_header { "Details" }
        box.with_body do
          form_with model: api_key, url: api_keys_path, local: true do |f|
            render Primer::Alpha::TextField.new(
              name: "api_key[name]",
              label: "Name",
              caption: "Short description (think \"high-seas\")",
              full_width: true,
              autofocus: true,
              mb: 3
            )

            fieldset(class: "fieldset-reset") do
              legend(class: "fieldset-legend") { "Permissions" }

              render Primer::Alpha::CheckBox.new(
                name: "api_key[pii]",
                label: "PII Access",
                caption: "Should this key be able to read address data? (probably not!)"
              )

              admin_tool do
                render Primer::Alpha::CheckBox.new(
                  name: "api_key[may_impersonate]",
                  label: "Can Impersonate",
                  caption: "Can this key impersonate other back office users? (don't enable unless needed)"
                )
              end
            end

            render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
              btn.with_leading_visual_icon(icon: :key)
              "Create API Key"
            end
          end
        end
      end

      render Components::Shared::BackButton.new(href: api_keys_path)
    end
  end

  private

  attr_reader :api_key
end
