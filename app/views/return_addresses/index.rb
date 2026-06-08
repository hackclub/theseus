# frozen_string_literal: true

class Views::ReturnAddresses::Index < Views::Base
  def initialize(return_addresses:, search: nil)
    @return_addresses = return_addresses
    @search = search
  end

  def view_template
    div(class: "page-container") do
      div(class: "page-header") do
        div(class: "page-title-group") do
          h1(class: "page-title") { "Return Addresses" }
          render Components::Shared::Jumpcode.new(path: return_addresses_path)
        end
        a(href: new_return_address_path) do
          button("variant-": "green") { "+ New Return Address" }
        end
      end

      div(class: "filter-bar-wrap") do
        div(class: "filter-search") do
          form(action: return_addresses_path, method: "get", class: "form-contents") do
            input(
              type: "text",
              name: "search",
              placeholder: "Search by name, address, city...",
              value: @search,
              style: "width: 100%;"
            )
          end
        end

        if @search.present?
          a(href: return_addresses_path, style: "color: var(--foreground2);") { "× Clear" }
        end
      end

      if return_addresses.any?
        div("box-": "round") do
          return_addresses.each do |address|
            render_address_row(address)
            div("is-": "separator") unless address == return_addresses.last
          end
        end
      else
        div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
          h2(style: "margin: 0;") { "No return addresses found" }
          p(style: "color: var(--foreground2);") { "Create your first return address to get started." }
          a(href: new_return_address_path) { button("variant-": "green") { "Create Return Address" } }
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
      span("is-": "badge", "variant-": "green") { "Default" }
    end

    if address.shared
      span("is-": "badge", "variant-": "blue") { "Shared" }
    end

    if address.user == current_user && address != current_user&.home_return_address
      span("is-": "badge") { "Mine" }
    end
  end

  def render_actions_menu(address)
    details(style: "position: relative; display: inline-block;") do
      summary(style: "cursor: pointer; list-style: none; color: var(--foreground2);") { "⋯" }
      div("box-": "round", style: "position: absolute; right: 0; z-index: 10; min-width: 20ch; padding: 0.5lh 0;") do
        a(href: edit_return_address_path(address), style: "display: block; padding: 0.25lh 1ch;") { "✎ Edit" }

        unless address == current_user&.home_return_address
          a(
            href: set_as_home_return_address_path(address),
            data: { turbo_method: :post },
            style: "display: block; padding: 0.25lh 1ch;"
          ) { "⌂ Set as Default" }
        end

        a(
          href: return_address_path(address),
          data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this return address?" },
          style: "display: block; padding: 0.25lh 1ch; color: var(--red);"
        ) { "✕ Delete" }
      end
    end
  end
end
