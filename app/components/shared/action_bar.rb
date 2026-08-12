# frozen_string_literal: true

class Components::Shared::ActionBar < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :request
  register_value_helper :impersonating?

  def view_template
    div(id: "theseus-actionbar", style: "display:flex;align-items:center;justify-content:space-between") do
      div(style: "display:flex;gap:0.5rem;align-items:center") do
        # mobile sidebar toggle
        button(
          class: "sidebar-toggle btn-sm",
          onclick: safe("toggleSidebar()")
        ) { "☰" }

        # brand
        a(href: root_path, style: "text-decoration:none;color:inherit") do
          b { "Theseus" }
          if Rails.env.development?
            sup(style: "color:GrayText;font-size:0.7em;margin-left:0.15rem") { "dev" }
          end
        end
      end

      div(style: "display:flex;gap:1rem;align-items:center") do
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
    span(style: "color:GrayText") do
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
    details(class: "popover", style: "position:relative") do
      summary(tabindex: "0", class: "btn-sm") do
        plain impersonating? ? "👁" : "👤"
      end

      div(style: "position:absolute;right:0;top:100%;min-width:8rem;background:Canvas;border:1px solid var(--background2);padding:0.5rem;display:flex;flex-direction:column") do
        span(style: "color:GrayText;padding-bottom:0.5rem") do
          plain current_user.username
        end
        hr
        a(
          href: signout_path,
          data: { method: :delete },
          style: "text-decoration:none;padding-top:0.5rem"
        ) { "Log out" }
      end
    end
  end

  def render_tasks_badge
    count = Rails.cache.read("user_tasks/#{current_user.id}")&.size
    a(href: tasks_path, style: "text-decoration:none;") do
      if count && count > 0
        span(class: "badge badge-info", style: "font-size:0.8em;") { count.to_s }
      else
        button(class: "btn-sm") { "✓" }
      end
    end
  end
end
