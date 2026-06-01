# frozen_string_literal: true

class Components::Shared::AppHeader < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :request
  register_value_helper :impersonating?

  def view_template
    header(class: "app-header") do
      div(class: "app-header-left") do
        render(Primer::Alpha::Dialog.new(
          title: "Navigation",
          position: :left,
          position_narrow: :fullscreen,
          size: :small,
          visually_hide_title: true
        )) do |dialog|
          dialog.with_show_button(icon: :"three-bars", "aria-label": "Menu", scheme: :default)
          dialog.with_body(padding: :none) do
            render Components::Shared::Nav.new
          end
        end

        span(class: "app-header-brand") do
          plain "Theseus"
          sup(class: "app-header-env-badge") { "dev" } if Rails.env.development?
        end

        render(Primer::Beta::IconButton.new(
          icon: :home,
          "aria-label": "Home",
          scheme: :invisible,
          tag: :a,
          href: root_path
        ))
      end

      div(class: "app-header-right") do
        render(Primer::Beta::IconButton.new(
          icon: :zap,
          "aria-label": "Mail Scanner",
          scheme: :invisible,
          tag: :a,
          href: scanner_letters_path
        ))

        render(Primer::Beta::Button.new(
          scheme: :invisible,
          size: :small,
          "aria-label": "Command palette",
          id: "kbar-trigger",
          onclick: safe("window.openKbar?.()")
        )) do |btn|
          btn.with_leading_visual_icon(icon: :search)
          span(class: "kbar-label") { "⌘K" }
        end

        render_id_lookup_dialog

        if current_user
          if impersonating?
            render(Primer::Beta::Label.new(scheme: :attention, size: :large)) do
              plain "Impersonating #{current_user.username}"
            end

            render(Primer::Beta::IconButton.new(
              icon: :skip,
              "aria-label": "Stop impersonating",
              scheme: :danger,
              tag: :a,
              href: stop_impersonating_path
            ))
          end

          render(Primer::Alpha::ActionMenu.new(anchor_align: :end)) do |menu|
            menu.with_show_button(scheme: :invisible) do |btn|
              btn.with_leading_visual_icon(icon: impersonating? ? :eye : :person)
              plain current_user.username
            end

            menu.with_item(label: "Log out", href: signout_path, data: {method: :delete}) do |item|
              item.with_leading_visual_icon(icon: :"sign-out")
            end
          end
        end
      end
    end
  end

  private

  def render_id_lookup_dialog
    render(Primer::Alpha::Dialog.new(
      title: "Find object by ID",
      subtitle: "Enter a Theseus ID or package tracking number...",
      size: :medium
    )) do |dialog|
      dialog.with_show_button(icon: :"id-badge", "aria-label": "Find object by ID", scheme: :invisible)
      dialog.with_body do
        form_with url: helpers.lookup_public_ids_path, method: :post do |f|
          render(Primer::Alpha::TextField.new(
            name: :id,
            label: nil,
            placeholder: "e.g. ltr!abc123, 9400111...",
            full_width: true,
            autofocus: true
          ))
          div(class: "dialog-form-footer") do
            render(Primer::ButtonComponent.new(type: :submit, scheme: :primary)) { "Go!" }
          end
        end
      end
    end
  end

end
