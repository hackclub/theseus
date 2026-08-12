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
          div(style: "margin-top:0.5rem;") do
            div(style: "display:flex;align-items:center;gap:0.5rem;") do
              input(type: "hidden", name: "settings[czar_po_emails]", value: "0")
              input(
                type: "checkbox",
                name: "settings[czar_po_emails]",
                value: "1",
                checked: @user.setting("czar_po_emails")
              )
              label { "Email me when new purchase orders are submitted for approval" }
            end
            small(class: "text-muted", style: "display:block;margin-top:0.25rem;margin-left:1.5rem;") do
              plain "You'll get an email each time a warehouse user submits a PO for czar review."
            end
          end
        else
          p(class: "text-muted", style: "margin:0.5rem 0 0;") { "No notification settings available for your account." }
        end
      end

      div(style: "margin-top:1rem;") do
        button(type: "submit", class: "btn-success") { "Save Settings" }
      end
    end
  end
end
