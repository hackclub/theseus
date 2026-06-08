# frozen_string_literal: true

class Views::ReturnAddresses::New < Views::Base
  def initialize(return_address:)
    @return_address = return_address
  end

  def view_template
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: return_addresses_path, style: "text-decoration: none; color: var(--foreground2);") { "← Return Addresses" }
        strong(style: "font-size: 1.15em;") { "New Return Address" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        div("box-": "round") do
          strong { "Address Details" }
          div("is-": "separator")
          render Components::ReturnAddresses::Form.new(return_address:)
        end
      end

      div(class: "show-sidebar") do
        div("box-": "round") do
          strong { "Info" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh; color: var(--foreground2);") do
            p(style: "margin: 0;") { "Return addresses appear as the sender on outgoing mail." }
          end
        end
      end
    end
  end

  private

  attr_reader :return_address
end
