# frozen_string_literal: true

class Views::ReturnAddresses::Edit < Views::Base
  def initialize(return_address:)
    @return_address = return_address
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: return_addresses_path, style: "text-decoration: none; color: var(--foreground2);") { "← Return Addresses" }
        strong(style: "font-size: 1.15em;") { "Edit Return Address" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        section do
          strong { "Address Details" }
          hr
          render Components::ReturnAddresses::Form.new(return_address:)
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "Current Address" }
          hr
          div(class: "detail-grid", style: "margin-top: 0.5rem;") do
            span(class: "detail-label") { "Name" }
            span { return_address.name.presence || "—" }
            span(class: "detail-label") { "Line 1" }
            span { return_address.line_1.presence || "—" }
            span(class: "detail-label") { "City" }
            span { return_address.city.presence || "—" }
            span(class: "detail-label") { "State" }
            span { return_address.state.presence || "—" }
            span(class: "detail-label") { "ZIP" }
            span { return_address.postal_code.presence || "—" }
            span(class: "detail-label") { "Country" }
            span { return_address.country.presence || "—" }
          end
        end
      end
    end
  end

  private

  attr_reader :return_address
end
