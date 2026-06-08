# frozen_string_literal: true

class Components::ReturnAddresses::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(return_address:, from_letter: false)
    @return_address = return_address
    @from_letter = from_letter
  end

  def view_template
    if return_address.errors.any?
      div(class: "error-box") do
        p(class: "error-box-title") do
          plain "#{return_address.errors.count} error(s) prohibited this return address from being saved:"
        end
        ul(class: "error-box-list") do
          return_address.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end

    form_with model: return_address, local: true do |f|
      div(class: "form-stack") do
        div(class: "form-grid-auto") do
          div(style: "margin-bottom: 1lh;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Name *" }
            input(type: "text", name: "return_address[name]", value: return_address.name, required: true, style: "width: 100%;")
            small(style: "color: var(--foreground2);") { "Organization or personal name" }
          end

          div(style: "margin-bottom: 1lh;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Address Line 1 *" }
            input(type: "text", name: "return_address[line_1]", value: return_address.line_1, required: true, style: "width: 100%;")
            small(style: "color: var(--foreground2);") { "Street address, P.O. box, etc." }
          end
        end

        div(style: "margin-bottom: 1lh;") do
          label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Address Line 2" }
          input(type: "text", name: "return_address[line_2]", value: return_address.line_2, style: "width: 100%;")
          small(style: "color: var(--foreground2);") { "Apartment, suite, unit, etc. (optional)" }
        end

        div(class: "form-grid-auto--sm") do
          div(style: "margin-bottom: 1lh;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "City *" }
            input(type: "text", name: "return_address[city]", value: return_address.city, required: true, style: "width: 100%;")
          end

          div(style: "margin-bottom: 1lh;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "State *" }
            input(type: "text", name: "return_address[state]", value: return_address.state, required: true, style: "width: 100%;")
          end

          div(style: "margin-bottom: 1lh;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Postal Code *" }
            input(type: "text", name: "return_address[postal_code]", value: return_address.postal_code, required: true, style: "width: 100%;")
          end
        end

        div do
          label(class: "date-field-label") do
            plain "Country"
            span(class: "text-danger") { "*" }
          end
          select(
            name: "return_address[country]",
            class: "form-select--lg"
          ) do
            option(value: "") { "Select a country..." }
            ReturnAddress.countries_for_select.each do |code, name|
              if return_address.country == code
                option(value: code, selected: true) { name }
              else
                option(value: code) { name }
              end
            end
          end
        end

        div(class: "checkbox-card") do
          label do
            input(type: "checkbox", name: "return_address[shared]", value: "1", checked: return_address.shared)
            plain " Make this address shared"
          end
          small(style: "color: var(--foreground2); display: block;") { "Allow other users to select this return address for their letters" }
        end

        input(type: "hidden", name: "return_address[user_id]", value: current_user&.id)
        input(type: "hidden", name: "from_letter", value: "true") if from_letter

        div(class: "pt-2") do
          button(type: "submit", "variant-": "green") do
            plain(return_address.persisted? ? "✓ Update Return Address" : "✓ Create Return Address")
          end
        end
      end
    end
  end

  private

  attr_reader :return_address, :from_letter
end
