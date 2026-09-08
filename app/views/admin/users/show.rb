# frozen_string_literal: true

class Views::Admin::Users::Show < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: @user.username || "User",
      action_href: edit_admin_user_path(@user),
      action_label: "✎ Edit"
    )

    # Avatar + identity
    section do
      if @user.icon_url.present?
        div(style: "margin-bottom:1rem;") do
          img(
            src: @user.icon_url,
            alt: @user.username,
            style: "width:64px;height:64px;border-radius:50%;object-fit:cover;"
          )
        end
      end

      div(class: "detail-grid") do
        span(class: "detail-label") { "Username" }
        span { @user.username || "—" }

        span(class: "detail-label") { "Email" }
        span { @user.email || "—" }

        span(class: "detail-label") { "Slack ID" }
        span(class: "text-muted") { @user.slack_id || "—" }

        span(class: "detail-label") { "HCA ID" }
        span(class: "text-muted") { @user.hca_id || "—" }

        span(class: "detail-label") { "Created" }
        span(class: "text-muted") { @user.created_at.strftime("%b %d, %Y %H:%M") }

        span(class: "detail-label") { "Updated" }
        span(class: "text-muted") { @user.updated_at.strftime("%b %d, %Y %H:%M") }
      end
    end

    # Permissions
    section do
      h3(style: "margin-top:0;") { "Permissions" }
      div(class: "detail-grid") do
        span(class: "detail-label") { "Admin" }
        span { permission_badge(@user.is_admin) }

        span(class: "detail-label") { "Indicia" }
        span { permission_badge(@user.can_use_indicia) }

        span(class: "detail-label") { "Warehouse" }
        span { permission_badge(@user.can_warehouse) }

        span(class: "detail-label") { "Impersonate Public" }
        span { permission_badge(@user.can_impersonate_public) }
      end
    end

    # Defaults
    section do
      h3(style: "margin-top:0;") { "Defaults" }
      div(class: "detail-grid") do
        span(class: "detail-label") { "Home Mailer ID" }
        span(class: "text-muted") do
          if @user.home_mid
            plain @user.home_mid.name.presence || @user.home_mid.mid
          else
            plain "—"
          end
        end

        span(class: "detail-label") { "Home Return Address" }
        span(class: "text-muted") do
          if @user.home_return_address
            plain @user.home_return_address.display_name
          else
            plain "—"
          end
        end
      end
    end

    # Stats
    section do
      h3(style: "margin-top:0;") { "Stats" }
      div(class: "detail-grid") do
        span(class: "detail-label") { "Letters" }
        span { @user.letters.size.to_s }

        span(class: "detail-label") { "Batches" }
        span { @user.batches.size.to_s }

        span(class: "detail-label") { "Warehouse Templates" }
        span { @user.warehouse_templates.size.to_s }

        span(class: "detail-label") { "Return Addresses" }
        span { @user.return_addresses.size.to_s }

        span(class: "detail-label") { "Letter Queues" }
        span { @user.letter_queues.size.to_s }
      end
    end

    # Feature Flags
    section do
      h3(style: "margin-top:0;") { "Feature Flags" }
      if Flipper.features.any?
        Flipper.features.sort_by(&:name).each do |flag|
          global = flag.state == :on
          user_enabled = flag.enabled?(@user)
          desc = Rails.configuration.flipper_features[flag.name]

          div(style: "display:flex;align-items:center;gap:0.5rem;padding:0.25rem 0;") do
            case flag.state
            when :on
              span(class: "badge badge-success") { "on" }
            when :off
              span(class: "badge") { "off" }
            when :conditional
              span(class: "badge badge-warning") { "cond" }
            end

            a(href: "#{flipper_path}/features/#{flag.name}", target: "_blank", style: "font-family:monospace;") { flag.name }

            if desc.present?
              abbr(title: desc, style: "color:var(--foreground2);cursor:help;") { "(?)" }
            end

            span(style: "flex:1;")

            if global
              span(style: "color:var(--foreground2);font-style:italic;") { "on for everyone" }
            elsif user_enabled
              span(class: "badge badge-success") { "enabled" }
              form_with(url: flip_admin_user_path(@user, flag: flag.name, state: false), method: :post, style: "display:inline;") do
                button(type: "submit", class: "btn-sm") { "disable" }
              end
            else
              span(style: "color:var(--foreground2);") { "disabled" }
              form_with(url: flip_admin_user_path(@user, flag: flag.name, state: true), method: :post, style: "display:inline;") do
                button(type: "submit", class: "btn-sm") { "enable" }
              end
            end
          end
        end
      else
        p(class: "text-muted") { "No feature flags configured." }
      end
    end

    # Impersonate
    if @user != current_user
      section do
        form_with(url: impersonate_user_path(@user), method: :post, style: "display:inline") do
          button(type: "submit", class: "btn-warning") { "🥸 Impersonate #{@user.username}" }
        end
      end
    end
  end

  private

  def permission_badge(value)
    if value
      span(class: "badge badge-success") { "Enabled" }
    else
      span(class: "badge") { "Disabled" }
    end
  end
end
