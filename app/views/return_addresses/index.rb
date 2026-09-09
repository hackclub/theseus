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
            th(class: "text-right") { "Actions" }
          end
        end
        tbody do
          return_addresses.each do |address|
            tr do
              td do
                a(href: edit_return_address_path(address), class: "link-strong") do
                  plain address.name
                end
                whitespace
                render_badges(address)
              end
              td(class: "text-muted") do
                parts = [ address.line_1 ]
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
              td(class: "text-right") do
                render_actions(address)
              end
            end
          end
        end
      end
    else
      div(class: "empty-state") do
        h2(class: "m-0") { "No return addresses found" }
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

    a(href: edit_return_address_path(address), class: "icon-link") { "✎" }

    unless address == current_user&.home_return_address
      a(
        href: set_as_home_return_address_path(address),
        data: { turbo_method: :post },
        class: "icon-link"
      ) { "⌂" }
    end

    button_to "✕", return_address_path(address), method: :delete, form: { class: "form-inline" }, class: "btn-link-danger", onclick: "return confirm('Are you sure you want to delete this return address?')"
  end
end
