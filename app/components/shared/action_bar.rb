# frozen_string_literal: true

class Components::Shared::ActionBar < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :request
  register_value_helper :impersonating?

  def view_template
    row( id: "theseus-actionbar", "align-": "center between") do
      row( "gap-": "1", "align-": "center") do
        # mobile sidebar toggle
        button(
          class: "sidebar-toggle",
          "size-": "small",
          onclick: safe("toggleSidebar()")
        ) { "☰" }

        # brand
        a(href: root_path, style: "text-decoration: none; color: var(--foreground0);") do
          b { "Theseus" }
          if Rails.env.development?
            sup(style: "color: var(--foreground2); font-size: 0.7em; margin-left: 0.3ch;") { "dev" }
          end
        end
      end

      row( "gap-": "2", "align-": "center") do
        render_user_context
        render_impersonation_banner if current_user && impersonating?

        # theme toggle
        button(
          "size-": "small",
          id: "theme-toggle",
          onclick: safe("(function(){var d=document.documentElement,t=d.dataset.webtuiTheme;var n=t.includes('dark')?'vitesse-light-soft':'gruvbox-dark-hard';d.dataset.webtuiTheme=n;localStorage.setItem('theme',n);this.textContent=n.includes('dark')?'☀':'☾'})()")
        ) { "☀" }

        # hints button
        button("size-": "small", onclick: safe("window.openHints && window.openHints()")) { "?" }

        # kbar button
        button("size-": "small", id: "kbar-trigger", onclick: safe("window.openKbar && window.openKbar()")) { "⌘K" }

        # user popover menu
        render_user_menu if current_user
      end
    end
  end

  private

  def render_user_context
    return unless current_user

    span(style: "color: var(--foreground2);") do
      plain current_user.username
    end
  end

  def render_impersonation_banner
    span(style: "color: var(--yellow); font-weight: bold;") do
      plain "⚠ Impersonating #{current_user.username}"
    end

    a(
      href: stop_impersonating_path,
      style: "color: var(--red); text-decoration: none; font-weight: bold;"
    ) { "Stop" }
  end

  def render_user_menu
    details(**{"is-" => "popover", "position-" => "bottom baseline-right"}) do
      summary(tabindex: "0", **{"size-" => "small"}) do
        plain impersonating? ? "👁" : "👤"
      end

      column( **{"gap-" => "0"}, style: "min-width: 16ch;") do
        span(style: "color: var(--foreground2); padding-bottom: 0.5lh;") do
          plain current_user.username
        end
        div(**{"is-" => "separator"})
        a(
          href: signout_path,
          data: { method: :delete },
          style: "color: var(--foreground0); text-decoration: none; padding-top: 0.5lh;"
        ) { "Log out" }
      end
    end
  end
end
