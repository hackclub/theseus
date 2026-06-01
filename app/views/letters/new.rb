# frozen_string_literal: true

class Views::Letters::New < Views::Base

  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(class: "page-container") do
      div(class: "page-title-group content-section") do
        render Primer::Beta::Button.new(tag: :a, href: letters_path, scheme: :invisible, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back"
        end
        h1(class: "page-title") { "New Letter" }
      end

      div(class: "batch-layout") do
        div do
          render Components::Letters::Form.new(letter: @letter)
        end

        div(class: "sticky-sidebar") do
          postage_rates_card
          size_limits_card
        end
      end
    end
  end

  private

  def postage_rates_card
    render Primer::Beta::BorderBox.new(mb: 3) do |box|
      box.with_header do |header|
        header.with_title(tag: :h3) { "Postage Rates" }
      end
      box.with_body do
        p(class: "rates-heading") { "Letters (stamps)" }
        table(class: "rates-table") do
          USPS::PricingEngine::US_STAMP_LETTER_RATES.first(4).each do |oz, price|
            tr do
              td { oz == oz.to_i ? "#{oz.to_i} oz" : "#{oz} oz" }
              td(class: "font-mono") { helpers.number_to_currency(price) }
            end
          end
        end

        p(class: "rates-heading") { "Flats (stamps)" }
        table(class: "rates-table") do
          USPS::PricingEngine::US_STAMP_FLAT_RATES.first(3).each do |oz, price|
            tr do
              td { oz == oz.to_i ? "#{oz.to_i} oz" : "#{oz} oz" }
              td(class: "font-mono") { helpers.number_to_currency(price) }
            end
          end
        end

        p(class: "rates-note") do
          plain "Non-machinable surcharge: +"
          plain helpers.number_to_currency(USPS::PricingEngine::FCMI_NON_MACHINABLE_SURCHARGE)
        end
        p(class: "rates-note") { "Indicia is slightly cheaper for standard letters." }
      end
    end
  end

  def size_limits_card
    render Primer::Beta::BorderBox.new do |box|
      box.with_header do |header|
        header.with_title(tag: :h3) { "Size Limits" }
      end
      box.with_body do
        dl(class: "size-dl") do
          dt { "Letter" }
          dd do
            raw "Up to 11.5 &times; 6.125 in, 3.5 oz"
          end
          dt { "Flat" }
          dd do
            raw "Up to 15 &times; 12 in, 13 oz"
          end
        end
      end
    end
  end
end
