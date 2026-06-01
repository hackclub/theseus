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
      render Primer::Alpha::SelectPanel.new(
        title: "Filter by user",
        size: :medium,
        fetch_strategy: :local,
        select_variant: :single,
        id: "user-picker-panel"
      ) do |panel|
        panel.with_show_button(scheme: :secondary, size: :medium) do |btn|
          if selected_user
            btn.with_leading_visual_icon(icon: :person) unless selected_user.icon_url.present?
            if selected_user.icon_url.present?
              render Primer::Beta::Avatar.new(src: selected_user.icon_url, alt: selected_user.email, size: 16, mr: 2)
            end
            plain display_name(selected_user)
          else
            btn.with_leading_visual_icon(icon: :people)
            "All users"
          end
        end

        all_users_item(panel)
        user_items(panel)
      end
    end
  end

  private

  attr_reader :users, :selected_user_id, :path_builder

  def selected_user
    return @selected_user if defined?(@selected_user)
    @selected_user = selected_user_id.present? ? users.find { |u| u.id == selected_user_id } : nil
  end

  def all_users_item(panel)
    panel.with_item(
      label: "All users",
      href: path_builder.call(nil),
      active: selected_user_id.blank?
    ) do |item|
      item.with_leading_visual_icon(icon: :people)
      item.with_description { "Show from everyone" }
    end
  end

  def user_items(panel)
    sorted_users = users.sort_by { |u| [u.id == current_user&.id ? 0 : 1, display_name(u).downcase] }
    sorted_users.each do |user|
      panel.with_item(
        label: display_name(user),
        href: path_builder.call(user.id),
        data: { filter_string: "#{user.email} #{user.username}" },
        active: user.id == selected_user_id
      ) do |item|
        if user.icon_url.present?
          item.with_leading_visual_content do
            img(src: user.icon_url, alt: user.email, class: "user-avatar")
          end
        else
          item.with_leading_visual_icon(icon: :person)
        end
        item.with_description { user.email }
      end
    end
  end

  def display_name(user)
    user.username.presence || user.email.split("@").first
  end
end
