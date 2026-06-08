# frozen_string_literal: true

class Views::ReturnAddresses::Index < Views::Base
  def initialize(return_addresses:, search: nil)
    @return_addresses = return_addresses
    @search = search
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Return Addresses",
      jumpcode_path: return_addresses_path,
      search_path: return_addresses_path,
      search_value: @search,
      search_placeholder: "Search by name, address, city...",
      action_href: new_return_address_path,
      action_label: "+ New Return Address"
    )

    if return_addresses.any?
      table do
        thead do
          tr do
            th { "Name" }
            th { "Address Line" }
            th { "City / State" }
            th { "Default?" }
            th(style: "text-align: right;") { "Actions" }
          end
        end
        tbody do
          return_addresses.each do |address|
            tr do
              td do
                a(href: edit_return_address_path(address), style: "text-decoration: none; color: var(--foreground0); font-weight: 600;") do
                  plain address.name
                end
                whitespace
                render_badges(address)
              end
              td(style: "color: var(--foreground2);") do
                parts = [address.line_1]
                parts << address.line_2 if address.line_2.present?
                plain parts.join(", ")
              end
              td(style: "color: var(--foreground2);") { plain "#{address.city}, #{address.state} #{address.postal_code}" }
              td do
                if address == current_user&.home_return_address
                  span("is-": "badge", "variant-": "green") { "Default" }
                else
                  plain "—"
                end
              end
              td(style: "text-align: right;") do
                render_actions(address)
              end
            end
          end
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

  private

  attr_reader :return_addresses

  def render_badges(address)
    if address.shared
      span("is-": "badge", "variant-": "blue") { "Shared" }
    end

    if address.user == current_user && address != current_user&.home_return_address
      span("is-": "badge") { "Mine" }
    end
  end

  def render_actions(address)
    return unless address.user == current_user || current_user&.admin?

    a(href: edit_return_address_path(address), style: "color: var(--foreground2); margin-right: 1ch;") { "✎" }

    unless address == current_user&.home_return_address
      a(
        href: set_as_home_return_address_path(address),
        data: { turbo_method: :post },
        style: "color: var(--foreground2); margin-right: 1ch;"
      ) { "⌂" }
    end

    a(
      href: return_address_path(address),
      data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this return address?" },
      style: "color: var(--red);"
    ) { "✕" }
  end
end
