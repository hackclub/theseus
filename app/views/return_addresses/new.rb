# frozen_string_literal: true

class Views::ReturnAddresses::New < Views::Base
  def initialize(return_address:)
    @return_address = return_address
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: return_addresses_path, style: "text-decoration: none; color: GrayText;") { "← Return Addresses" }
        strong(style: "font-size: 1.15em;") { "New Return Address" }
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
          strong { "Info" }
          hr
          div(style: "margin-top: 0.5rem; color: GrayText;") do
            p(style: "margin: 0;") { "Return addresses appear as the sender on outgoing mail." }
          end
        end
      end
    end
  end

  private

  attr_reader :return_address
end
