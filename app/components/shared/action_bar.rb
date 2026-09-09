# frozen_string_literal: true

class Components::Shared::ActionBar < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :request
  register_value_helper :impersonating?

  def view_template
    div(id: "theseus-actionbar") do
      div(class: "flex-row") do
        # mobile sidebar toggle
        button(
          class: "sidebar-toggle btn-sm",
          onclick: safe("toggleSidebar()")
        ) { "☰" }

        # brand
        a(href: root_path, class: "link-reset") do
          b { "Theseus" }
          if Rails.env.development?
            sup(class: "dev-badge") { "dev" }
          end
        end
      end

      div(class: "actionbar-right") do
        render_user_context
        render_impersonation_banner if current_user && impersonating?

        # tasks badge
        render_tasks_badge if current_user

        # hints button
        button(class: "btn-sm", onclick: safe("window.openHints && window.openHints()")) { "?" }

        # kbar button
        button(class: "btn-sm", id: "kbar-trigger", onclick: safe("window.openKbar && window.openKbar()")) { "⌘K" }

        # user popover menu
        render_user_menu if current_user
      end
    end
  end

  private

  def render_user_context
    return unless current_user
    span(class: "text-muted") do
      plain current_user.username
    end
  end

  def render_impersonation_banner
    span(class: "impersonation-warning") do
      plain "⚠ Impersonating #{current_user.username}"
    end

    form_with(url: stop_impersonating_path, method: :delete, class: "form-inline") do
      button(
        type: "submit",
        class: "impersonation-stop-btn"
      ) { "Stop" }
    end
  end

  def render_user_menu
    details(class: "popover") do
      summary(tabindex: "0", class: "btn-sm") do
        plain impersonating? ? "👁" : "👤"
      end

      div(class: "user-menu-panel") do
        span(class: "user-menu-username") do
          plain current_user.username
        end
        hr
        button_to "Log out", signout_path, method: :delete, class: "user-menu-logout-btn"
      end
    end
  end

  def render_tasks_badge
    count = Rails.cache.read("user_tasks/#{current_user.id}")&.size
    a(href: tasks_path, class: "no-underline") do
      if count && count > 0
        span(class: "badge badge-info tasks-badge-count") { count.to_s }
      else
        button(class: "btn-sm") { "✓" }
      end
    end
  end
end
