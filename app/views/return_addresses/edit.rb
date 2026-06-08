# frozen_string_literal: true

class Views::ReturnAddresses::Edit < Views::Base
  def initialize(return_address:)
    @return_address = return_address
  end

  def view_template
    div(class: "page-container--sm") do
      h1(class: "page-title content-section") { "Edit Return Address" }

      div("box-": "round", style: "margin-bottom: 3lh;") do
        h3(style: "margin: 0;") { "Address Details" }
        div("is-": "separator")
        render Components::ReturnAddresses::Form.new(return_address:)
      end

      render Components::Shared::BackButton.new(href: return_addresses_path)
    end
  end

  private

  attr_reader :return_address
end
