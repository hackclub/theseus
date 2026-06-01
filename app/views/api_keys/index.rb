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
        render Primer::Beta::Button.new(tag: :a, href: new_api_key_path, scheme: :primary) do |btn|
          btn.with_leading_visual_icon(icon: :key)
          "Visit the locksmith!"
        end
      end

      if api_keys.any?
        render Primer::Beta::BorderBox.new do |box|
          api_keys.each do |key|
            box.with_row do
              a(href: api_key_path(key), class: "api-key-row") do
                div(class: "api-key-row-layout") do
                  div(class: "flex-1") do
                    div(class: "page-title-group mb-0") do
                      span(class: "fw-semibold") { key.pretty_name }
                      render Primer::Beta::Label.new(scheme: key.active? ? :success : :secondary) do
                        key.active? ? "Active" : "Revoked"
                      end
                    end
                    span(class: "text-sm kv-label") { "Acts as: #{key.user.username}" }
                  end

                  div(class: "page-actions") do
                    render(Primer::Beta::Label.new(scheme: :attention)) { "PII" } if key.pii
                    render(Primer::Beta::Label.new(scheme: :danger)) { "Impersonate" } if key.may_impersonate?
                  end
                end
              end
            end
          end
        end
      else
        render Primer::Beta::Blankslate.new(border: true) do |bs|
          bs.with_visual_icon(icon: :key)
          bs.with_heading(tag: :h2) { "No API keys yet" }
        end
      end
    end
  end

  private

  attr_reader :api_keys
end
