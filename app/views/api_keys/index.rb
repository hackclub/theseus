# frozen_string_literal: true

class Views::APIKeys::Index < Views::Base
  def initialize(api_keys:)
    @api_keys = api_keys
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageToolbar.new(
        title: "API Keys",
        jumpcode_path: api_keys_path,
        action_href: new_api_key_path,
        action_label: "+ New Key",
        action_variant: "green"
      )

      if api_keys.any?
        table do
          thead do
            tr do
              th { "Name" }
              th { "Key" }
              th { "Created" }
              th { "Status" }
            end
          end
          tbody do
            api_keys.each do |key|
              tr do
                td do
                  a(href: api_key_path(key), style: "text-decoration: none;") do
                    plain key.pretty_name
                  end
                end
                td(class: "text-muted", style: "font-size: 0.85em;") do
                  plain (key.abbreviated rescue "••••••••")
                end
                td(class: "text-muted") { plain key.created_at.strftime("%b %d, %Y") }
                td do
                  status_badges(key)
                end
              end
            end
          end
        end
      else
        div(style: "text-align: center; padding: 2rem;") do
          h2(style: "margin: 0;") { "🔑" }
          h3(style: "margin: 0;") { "No API keys yet" }
        end
      end
    end
  end

  private

  attr_reader :api_keys

  def status_badges(key)
    if key.active?
      span(class: "badge badge-success") { "Active" }
    else
      span(class: "badge") { "Revoked" }
    end
    whitespace
    if key.pii
      span(class: "badge badge-warning") { "PII" }
      whitespace
    end
    if key.may_impersonate?
      span(class: "badge badge-danger") { "Impersonate" }
    end
  end
end
