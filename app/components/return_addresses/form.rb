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
          render Primer::Alpha::TextField.new(
            name: "return_address[name]",
            label: "Name",
            value: return_address.name,
            caption: "Organization or personal name",
            full_width: true,
            required: true
          )

          render Primer::Alpha::TextField.new(
            name: "return_address[line_1]",
            label: "Address Line 1",
            value: return_address.line_1,
            caption: "Street address, P.O. box, etc.",
            full_width: true,
            required: true
          )
        end

        render Primer::Alpha::TextField.new(
          name: "return_address[line_2]",
          label: "Address Line 2",
          value: return_address.line_2,
          caption: "Apartment, suite, unit, etc. (optional)",
          full_width: true
        )

        div(class: "form-grid-auto--sm") do
          render Primer::Alpha::TextField.new(
            name: "return_address[city]",
            label: "City",
            value: return_address.city,
            full_width: true,
            required: true
          )

          render Primer::Alpha::TextField.new(
            name: "return_address[state]",
            label: "State",
            value: return_address.state,
            full_width: true,
            required: true
          )

          render Primer::Alpha::TextField.new(
            name: "return_address[postal_code]",
            label: "Postal Code",
            value: return_address.postal_code,
            full_width: true,
            required: true
          )
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
          render Primer::Alpha::CheckBox.new(
            name: "return_address[shared]",
            label: "Make this address shared",
            caption: "Allow other users to select this return address for their letters",
            checked: return_address.shared
          )
        end

        input(type: "hidden", name: "return_address[user_id]", value: current_user&.id)
        input(type: "hidden", name: "from_letter", value: "true") if from_letter

        div(class: "pt-2") do
          render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :check)
            return_address.persisted? ? "Update Return Address" : "Create Return Address"
          end
        end
      end
    end
  end

  private

  attr_reader :return_address, :from_letter
end
