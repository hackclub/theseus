# frozen_string_literal: true

class Views::ReturnAddresses::Index < Views::Base
  def initialize(return_addresses:)
    @return_addresses = return_addresses
  end

  def view_template
    div(class: "page-container") do
      div(class: "page-header") do
        div(class: "page-title-group") do
          h1(class: "page-title") { "Return Addresses" }
          render Components::Shared::Jumpcode.new(path: return_addresses_path)
        end
        render Primer::Beta::Button.new(tag: :a, href: new_return_address_path, scheme: :primary) do |btn|
          btn.with_leading_visual_icon(icon: :plus)
          "New Return Address"
        end
      end

      if return_addresses.any?
        render Primer::Beta::BorderBox.new do |box|
          return_addresses.each do |address|
            box.with_row do
              render_address_row(address)
            end
          end
        end
      else
        render Primer::Beta::Blankslate.new(border: true) do |bs|
          bs.with_visual_icon(icon: :location)
          bs.with_heading(tag: :h2) { "No return addresses found" }
          bs.with_description { "Create your first return address to get started." }
          bs.with_primary_action(href: new_return_address_path) { "Create Return Address" }
        end
      end
    end
  end

  private

  attr_reader :return_addresses

  def render_address_row(address)
    div(class: "return-address-row") do
      div(class: "flex-1") do
        div(class: "order-collection-header") do
          span(class: "fw-semibold") { address.name }
          render_badges(address)
        end

        div(class: "index-card-meta") do
          parts = [address.line_1]
          parts << address.line_2 if address.line_2.present?
          parts << "#{address.city}, #{address.state} #{address.postal_code}"
          parts << address.country
          plain parts.join(" · ")
        end
      end

      render_actions_menu(address) if address.user == current_user || current_user&.admin?
    end
  end

  def render_badges(address)
    if address == current_user&.home_return_address
      render(Primer::Beta::Label.new(scheme: :success)) { plain "Default" }
    end

    if address.shared
      render(Primer::Beta::Label.new(scheme: :accent)) { plain "Shared" }
    end

    if address.user == current_user && address != current_user&.home_return_address
      render(Primer::Beta::Label.new(scheme: :secondary)) { plain "Mine" }
    end
  end

  def render_actions_menu(address)
    render Primer::Alpha::ActionMenu.new do |menu|
      menu.with_show_button(icon: :"kebab-horizontal", "aria-label": "Actions", scheme: :invisible)

      menu.with_item(label: "Edit", href: edit_return_address_path(address)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end

      unless address == current_user&.home_return_address
        menu.with_item(
          label: "Set as Default",
          href: set_as_home_return_address_path(address),
          content_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :home)
        end
      end

      menu.with_item(
        label: "Delete",
        scheme: :danger,
        href: return_address_path(address),
        content_arguments: {
          method: :delete,
          data: { confirm: "Are you sure you want to delete this return address?" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
