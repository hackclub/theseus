# frozen_string_literal: true

class Views::Admin::Users::Index < Views::Base
  def initialize(users:)
    @users = users
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Users",
      jumpcode_path: admin_users_path,
      search_path: admin_users_path,
      search_placeholder: "Search users...",
      action_href: new_admin_user_path,
      action_label: "+ New User"
    )

    table do
      thead do
        tr do
          th(class: "col-avatar") { "" }
          th { "Username" }
          th { "Email" }
          th { "Roles" }
          th { "Letters" }
          th { "Orders" }
          th(class: "text-muted text-right") { "Joined" }
        end
      end
      tbody do
        @users.each do |user|
          tr do
            td(class: "cell-pad") do
              if user.icon_url.present?
                img(
                  src: user.icon_url,
                  alt: user.username,
                  width: 24,
                  height: 24,
                  class: "avatar-round object-cover align-middle"
                )
              end
            end
            td do
              a(href: admin_user_path(user), class: "link-strong") { user.username || "—" }
            end
            td(class: "text-muted") { user.email || "—" }
            td { role_badges(user) }
            td(class: "text-muted") { user.letter_count.to_s }
            td(class: "text-muted") { user.warehouse_order_count.to_s }
            td(class: "text-muted text-right") { user.created_at.strftime("%b %d, %Y") }
          end
        end
      end
    end
  end

  private

  def role_badges(user)
    if user.is_admin
      span(class: "badge badge-danger mr-quarter") { "Admin" }
    end
    if user.can_warehouse
      span(class: "badge badge-info mr-quarter") { "Warehouse" }
    end
    if user.can_use_indicia
      span(class: "badge badge-warning mr-quarter") { "Indicia" }
    end
  end
end
