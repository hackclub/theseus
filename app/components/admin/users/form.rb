# frozen_string_literal: true

class Components::Admin::Users::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:)
    @user = user
  end

  def view_template
    if @user.errors.any?
      div(class: "banner banner-alert") do
        plain @user.errors.full_messages.to_sentence
      end
    end

    form_with model: @user, url: form_url, method: form_method, local: true do |f|
      div(class: "form-stack") do
        # Identity
        render Components::Shared::FormField.new(label: "Username", name: "user[username]", value: @user.username)
        render Components::Shared::FormField.new(label: "Email", name: "user[email]", value: @user.email, type: "email")
        render Components::Shared::FormField.new(label: "Slack ID", name: "user[slack_id]", value: @user.slack_id, hint: "Slack member ID")
        render Components::Shared::FormField.new(label: "HCA ID", name: "user[hca_id]", value: @user.hca_id, hint: "Hack Club Airtable ID")
        render Components::Shared::FormField.new(label: "Icon URL", name: "user[icon_url]", value: @user.icon_url, hint: "Avatar image URL")

        # Permissions section
        div(style: "margin-top:1.5rem;margin-bottom:1rem;") do
          h3(style: "margin:0 0 0.5rem;") { "Permissions" }

          checkbox_field("Admin", "user[is_admin]", @user.is_admin)
          checkbox_field("Can Use Indicia", "user[can_use_indicia]", @user.can_use_indicia)
          checkbox_field("Can Warehouse", "user[can_warehouse]", @user.can_warehouse)
          checkbox_field("Warehouse Czar", "user[is_warehouse_czar]", @user.is_warehouse_czar)
          checkbox_field("Can Impersonate Public", "user[can_impersonate_public]", @user.can_impersonate_public)
        end

        # Defaults section
        div(style: "margin-top:1.5rem;margin-bottom:1rem;") do
          h3(style: "margin:0 0 0.5rem;") { "Defaults" }

          select_field("Home Mailer ID", "user[home_mid_id]", mailer_id_options, @user.home_mid_id)
          select_field("Home Return Address", "user[home_return_address_id]", return_address_options, @user.home_return_address_id)
        end

        div(style: "padding-top:1rem;") do
          button(type: "submit", class: "btn-success") { @user.persisted? ? "Update User" : "Create User" }
        end
      end
    end
  end

  def form_url
    @user.persisted? ? admin_user_path(@user) : admin_users_path
  end

  def form_method
    @user.persisted? ? :patch : :post
  end

  private

  def checkbox_field(label_text, name, value)
    div(style: "margin-bottom:0.75rem;display:flex;align-items:center;gap:0.5rem;") do
      input(type: "hidden", name: name, value: "0")
      input(type: "checkbox", name: name, value: "1", checked: value, style: "margin:0;")
      label(style: "color:var(--foreground2);margin:0;") { label_text }
    end
  end

  def select_field(label_text, name, options, selected_value)
    render Components::Shared::FormField.new(label: label_text, input: false) do
      select(name: name, class: "form-field-input") do
        option(value: "") { "— None —" }
        options.each do |opt_label, id|
          if id.to_s == selected_value.to_s
            option(value: id, selected: true) { opt_label }
          else
            option(value: id) { opt_label }
          end
        end
      end
    end
  end

  def mailer_id_options
    USPS::MailerId.all.map do |mid|
      label = mid.name.presence || mid.mid
      [ label, mid.id ]
    end
  end

  def return_address_options
    ReturnAddress.all.map do |addr|
      [ addr.display_name, addr.id ]
    end
  end
end
