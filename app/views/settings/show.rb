# frozen_string_literal: true

class Views::Settings::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Settings",
      jumpcode_path: settings_path
    )

    form_with url: settings_path, method: :patch, local: true do |f|
      section do
        strong { "Notifications" }
        hr

        if @user.warehouse_czar?
          div(class: "mt-half") do
            div(class: "flex-row") do
              input(type: "hidden", name: "settings[czar_notifications]", value: "0")
              input(
                type: "checkbox",
                name: "settings[czar_notifications]",
                value: "1",
                checked: @user.setting("czar_notifications")
              )
              label { "Email me about warehouse approvals" }
            end
            small(class: "text-muted checkbox-note") do
              plain "You'll get an email when SKU requests and purchase orders are submitted for review."
            end
          end
        else
          p(class: "text-muted mt-half-reset") { "No notification settings available for your account." }
        end
      end

      div(class: "mt-1") do
        button(type: "submit", class: "btn-success") { "Save Settings" }
      end
    end
  end
end
