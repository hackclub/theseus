# frozen_string_literal: true

class Views::ReturnAddresses::New < Views::Base
  def initialize(return_address:)
    @return_address = return_address
  end

  def view_template
    div(class: "page-container--sm") do
      h1(class: "page-title content-section") { "New Return Address" }

      render Primer::Beta::BorderBox.new(mb: 3) do |box|
        box.with_header { "Address Details" }
        box.with_body do
          render Components::ReturnAddresses::Form.new(return_address:)
        end
      end

      render Components::Shared::BackButton.new(href: return_addresses_path)
    end
  end

  private

  attr_reader :return_address
end
