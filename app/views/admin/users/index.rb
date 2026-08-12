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
      search_placeholder: "Search users..."
    )

    table do
      thead do
        tr do
          th(style: "width:2.5rem;") { "" }
          th { "Username" }
          th { "Email" }
          th { "Roles" }
          th { "Letters" }
          th { "Orders" }
          th(class: "text-muted", style: "text-align:right;") { "Joined" }
        end
      end
      tbody do
        @users.each do |user|
          tr do
            td(style: "padding:0.25rem 0.5rem;") do
              if user.icon_url.present?
                img(
                  src: user.icon_url,
                  alt: user.username,
                  style: "width:24px;height:24px;border-radius:50%;object-fit:cover;vertical-align:middle;"
                )
              end
            end
            td do
              a(href: admin_user_path(user), style: "text-decoration:none;font-weight:600;") { user.username || "—" }
            end
            td(class: "text-muted") { user.email || "—" }
            td { role_badges(user) }
            td(class: "text-muted") { user.letters.size.to_s }
            td(class: "text-muted") { user.warehouse_templates.size.to_s }
            td(class: "text-muted", style: "text-align:right;") { user.created_at.strftime("%b %d, %Y") }
          end
        end
      end
    end
  end

  private

  def role_badges(user)
    if user.is_admin
      span(class: "badge badge-danger", style: "margin-right:0.25rem;") { "Admin" }
    end
    if user.can_warehouse
      span(class: "badge badge-info", style: "margin-right:0.25rem;") { "Warehouse" }
    end
    if user.can_use_indicia
      span(class: "badge badge-warning", style: "margin-right:0.25rem;") { "Indicia" }
    end
  end
end
