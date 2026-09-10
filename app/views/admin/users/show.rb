# frozen_string_literal: true

class Views::Admin::Users::Show < Views::Base
  include Components::Shared::BillingHelpers
  include Phlex::Rails::Helpers::FormWith

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
        div(class: "mb-1") do
          img(
            src: @user.icon_url,
            alt: @user.username,
            width: 64,
            height: 64,
            class: "avatar-round object-cover"
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
      h3(class: "mt-0") { "Permissions" }
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
      h3(class: "mt-0") { "Defaults" }
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

    # Activity
    section do
      h3(class: "mt-0") { "Activity" }
      div(class: "detail-grid") do
        stat_link "Letters", @user.letters.count, letters_path(user_id: @user.id)
        stat_link "Letter Batches", ::Letter::Batch.where(user_id: @user.id).count, letter_batches_path(user_id: @user.id)
        stat_link "Letter Queues", @user.letter_queues.count, letter_queues_path(user_id: @user.id)
        stat_link "Warehouse Orders", @user.warehouse_orders.count, warehouse_orders_path(user_id: @user.id)
        stat_link "Warehouse Batches", ::Warehouse::Batch.where(user_id: @user.id).count, warehouse_batches_path(user_id: @user.id)

        span(class: "detail-label") { "Warehouse Templates" }
        span { @user.warehouse_templates.count.to_s }

        span(class: "detail-label") { "Return Addresses" }
        span { @user.return_addresses.count.to_s }
      end
    end

    # Feature Flags
    section do
      h3(class: "mt-0") { "Feature Flags" }
      if Flipper.features.any?
        Flipper.features.sort_by(&:name).each do |flag|
          global = flag.state == :on
          user_enabled = flag.enabled?(@user)
          desc = Rails.configuration.flipper_features[flag.name]

          div(class: "flag-row") do
            case flag.state
            when :on
              span(class: "badge badge-success") { "on" }
            when :off
              span(class: "badge") { "off" }
            when :conditional
              span(class: "badge badge-warning") { "cond" }
            end

            a(href: "#{flipper_path}/features/#{flag.name}", target: "_blank", class: "mono") { flag.name }

            if desc.present?
              abbr(title: desc, class: "help-hint") { "(?)" }
            end

            span(class: "flex-1")

            if global
              span(class: "text-muted-italic") { "on for everyone" }
            elsif user_enabled
              span(class: "badge badge-success") { "enabled" }
              form_with(url: flip_admin_user_path(@user, flag: flag.name, state: false), method: :post, class: "form-inline") do
                button(type: "submit", class: "btn-sm") { "disable" }
              end
            else
              span(class: "text-muted") { "disabled" }
              form_with(url: flip_admin_user_path(@user, flag: flag.name, state: true), method: :post, class: "form-inline") do
                button(type: "submit", class: "btn-sm") { "enable" }
              end
            end
          end
        end
      else
        p(class: "text-muted") { "No feature flags configured." }
      end
    end

    # Recent Billing
    billing_profiles = @user.billing_profiles.to_a
    if billing_profiles.any?
      recent_entries = ::LedgerEntry
        .where(billing_profile: billing_profiles)
        .includes(:billing_profile, :ledgerable)
        .order(created_at: :desc)
        .limit(20)

      section do
        h3(class: "mt-0") do
          plain "Recent Billing"
          span(class: "text-muted billing-orgs-label") do
            plain "(#{billing_profiles.map(&:organization_name).join(", ")})"
          end
        end

        if recent_entries.any?
          table do
            thead do
              tr do
                th { "Date" }
                th { "Category" }
                th { "Amount" }
                th { "For" }
                th { "State" }
              end
            end
            tbody do
              recent_entries.each do |entry|
                tr do
                  td(class: "text-muted") { entry.created_at.strftime("%b %d %H:%M") }
                  td { span(class: "badge badge-info") { entry.category } }
                  td(class: "fw-600") { "#{entry.credit? ? "-" : ""}$#{"%.2f" % entry.amount.abs}" }
                  td { ledgerable_link(entry) }
                  td { state_badge(entry.state) }
                end
              end
            end
          end
        else
          p(class: "text-muted") { "No billing activity yet." }
        end
      end
    end

    # Impersonate
    if @user != current_user
      section do
        form_with(url: impersonate_user_path(@user), method: :post, class: "form-inline") do
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

  def stat_link(label, count, path)
    span(class: "detail-label") { label }
    span { a(href: path) { count.to_s } }
  end
end
