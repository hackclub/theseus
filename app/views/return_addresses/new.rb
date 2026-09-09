# frozen_string_literal: true

class Views::ReturnAddresses::New < Views::Base
  def initialize(return_address:)
    @return_address = return_address
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: return_addresses_path, class: "link-muted") { "← Return Addresses" }
        strong(class: "text-title") { "New Return Address" }
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
          div(class: "mt-half text-muted") do
            p(class: "m-0") { "Return addresses appear as the sender on outgoing mail." }
          end
        end
      end
    end
  end

  private

  attr_reader :return_address
end
