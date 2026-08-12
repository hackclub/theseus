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
                a(href: edit_return_address_path(address), style: "text-decoration: none; font-weight: 600;") do
                  plain address.name
                end
                whitespace
                render_badges(address)
              end
              td(class: "text-muted") do
                parts = [address.line_1]
                parts << address.line_2 if address.line_2.present?
                plain parts.join(", ")
              end
              td(class: "text-muted") { plain "#{address.city}, #{address.state} #{address.postal_code}" }
              td do
                if address == current_user&.home_return_address
                  span(class: "badge badge-success") { "Default" }
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
      div(style: "text-align: center; padding: 2rem;") do
        h2(style: "margin: 0;") { "No return addresses found" }
        p(class: "text-muted") { "Create your first return address to get started." }
        a(href: new_return_address_path) { button(class: "btn-success") { "Create Return Address" } }
      end
    end
  end

  private

  attr_reader :return_addresses

  def render_badges(address)
    if address.shared
      span(class: "badge badge-info") { "Shared" }
    end

    if address.user == current_user && address != current_user&.home_return_address
      span(class: "badge") { "Mine" }
    end
  end

  def render_actions(address)
    return unless address.user == current_user || current_user&.admin?

    a(href: edit_return_address_path(address), style: "color: GrayText; margin-right: 0.5rem;") { "✎" }

    unless address == current_user&.home_return_address
      a(
        href: set_as_home_return_address_path(address),
        data: { turbo_method: :post },
        style: "color: GrayText; margin-right: 0.5rem;"
      ) { "⌂" }
    end

    button_to "✕", return_address_path(address), method: :delete, form: { style: "display:inline;" }, style: "background:none;border:none;color:var(--red);cursor:pointer;font:inherit;padding:0;", onclick: "return confirm('Are you sure you want to delete this return address?')"
  end
end
