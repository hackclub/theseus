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

    form_with model: @user, url: admin_user_path(@user), local: true do |f|
      div(class: "form-stack") do
        # Identity
        form_field("Username", "user[username]", @user.username)
        form_field("Email", "user[email]", @user.email, type: "email")
        form_field("Slack ID", "user[slack_id]", @user.slack_id, hint: "Slack member ID")
        form_field("HCA ID", "user[hca_id]", @user.hca_id, hint: "Hack Club Airtable ID")
        form_field("Icon URL", "user[icon_url]", @user.icon_url, hint: "Avatar image URL")

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
          button(type: "submit", class: "btn-success") { "Update User" }
        end
      end
    end
  end

  private

  def form_field(label_text, name, value, required: false, type: "text", hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") do
        plain label_text
        plain " *" if required
      end
      input(type: type, name: name, value: value, required: required, style: "width:100%;")
      if hint
        small(class: "text-muted") { hint }
      end
    end
  end

  def checkbox_field(label_text, name, value)
    div(style: "margin-bottom:0.75rem;display:flex;align-items:center;gap:0.5rem;") do
      input(type: "hidden", name: name, value: "0")
      input(type: "checkbox", name: name, value: "1", checked: value, style: "margin:0;")
      label(style: "color:GrayText;margin:0;") { label_text }
    end
  end

  def select_field(label_text, name, options, selected_value)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { label_text }
      select(name: name, style: "width:100%;") do
        option(value: "") { "— None —" }
        options.each do |label, id|
          if id.to_s == selected_value.to_s
            option(value: id, selected: true) { label }
          else
            option(value: id) { label }
          end
        end
      end
    end
  end

  def mailer_id_options
    USPS::MailerId.all.map do |mid|
      label = mid.name.presence || mid.mid
      [label, mid.id]
    end
  end

  def return_address_options
    ReturnAddress.all.map do |addr|
      [addr.display_name, addr.id]
    end
  end
end
