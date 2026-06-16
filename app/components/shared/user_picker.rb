# frozen_string_literal: true

class Components::Shared::UserPicker < Components::Base
  # path_builder: a lambda that takes (user_id) and returns the URL
  # Example: ->(uid) { warehouse_orders_path(user_id: uid, view: view) }
  def initialize(users:, selected_user_id: nil, path_builder:)
    @users = users.to_a
    @selected_user_id = selected_user_id.to_i if selected_user_id.present?
    @path_builder = path_builder
  end

  def view_template
    return unless current_user&.is_admin?

    div(id: "user-picker-container") do
      details(class: "popover", style: "position:relative") do
        summary(tabindex: "0", class: "btn-sm") do
          if selected_user
            if selected_user.icon_url.present?
              img(src: selected_user.icon_url, alt: selected_user.email, style: "width:1rem;height:1rem;vertical-align:middle;margin-right:0.25rem")
            else
              plain "👤 "
            end
            plain display_name(selected_user)
          else
            plain "👤 All users"
          end
          plain " ▾"
        end
        div(style: "position:absolute;left:0;top:100%;background:Canvas;border:1px solid var(--background2);padding:0.5rem;display:flex;flex-direction:column") do
          a(href: path_builder.call(nil), style: selected_user_id.blank? ? "font-weight:bold" : nil) do
            plain "👤 All users"
          end
          sorted_users.each do |user|
            a(href: path_builder.call(user.id), style: user.id == selected_user_id ? "font-weight:bold" : nil) do
              if user.icon_url.present?
                img(src: user.icon_url, alt: user.email, style: "width:1rem;height:1rem;vertical-align:middle;margin-right:0.25rem")
              else
                plain "👤 "
              end
              plain display_name(user)
            end
          end
        end
      end
    end
  end

  private

  attr_reader :users, :selected_user_id, :path_builder

  def selected_user
    return @selected_user if defined?(@selected_user)
    @selected_user = selected_user_id.present? ? users.find { |u| u.id == selected_user_id } : nil
  end

  def sorted_users
    @sorted_users ||= users.sort_by { |u| [u.id == current_user&.id ? 0 : 1, display_name(u).downcase] }
  end

  def display_name(user)
    user.username.presence || user.email.split("@").first
  end
end
