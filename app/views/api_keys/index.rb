# frozen_string_literal: true

class Views::APIKeys::Index < Views::Base
  def initialize(api_keys:)
    @api_keys = api_keys
  end

  def view_template
    div(class: "page-container") do
      div(class: "page-header") do
        div(class: "page-title-group") do
          h1(class: "page-title") { "API Keys" }
          render Components::Shared::Jumpcode.new(path: api_keys_path)
        end
        a(href: new_api_key_path) do
          button("size-": "small", "variant-": "green") { "🔑 Visit the locksmith!" }
        end
      end

      if api_keys.any?
        div("box-": "round") do
          api_keys.each_with_index do |key, i|
            div("is-": "separator") if i > 0
            a(href: api_key_path(key), class: "api-key-row") do
              div(class: "api-key-row-layout") do
                div(class: "flex-1") do
                  div(class: "page-title-group mb-0") do
                    span(class: "fw-semibold") { key.pretty_name }
                    span("is-": "badge", "variant-": key.active? ? "green" : "background2") do
                      key.active? ? "Active" : "Revoked"
                    end
                  end
                  span(class: "text-sm kv-label") { "Acts as: #{key.user.username}" }
                end

                div(class: "page-actions") do
                  if key.pii
                    span("is-": "badge", "variant-": "yellow") { "PII" }
                  end
                  if key.may_impersonate?
                    span("is-": "badge", "variant-": "red") { "Impersonate" }
                  end
                end
              end
            end
          end
        end
      else
        div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
          h2(style: "margin: 0;") { "🔑" }
          h3(style: "margin: 0;") { "No API keys yet" }
        end
    end
  end

  private

  attr_reader :api_keys
end
