# frozen_string_literal: true

class Views::Letters::New < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: letters_path, style: "text-decoration: none; color: var(--foreground2);") { "← Letters" }
        strong(style: "font-size: 1.15em;") { "New Letter" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        render Components::Letters::Form.new(letter: @letter)
      end

      div(class: "show-sidebar") do
        postage_rates_card
        size_limits_card
      end
    end
  end

  private

  def postage_rates_card
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Postage Rates" }
      div("is-": "separator")

      span(style: "color: var(--foreground2); font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.05ch;") { "Letters (stamps)" }
      table(style: "margin-bottom: 0.5lh;") do
        USPS::PricingEngine::US_STAMP_LETTER_RATES.first(4).each do |oz, price|
          tr do
            td(style: "color: var(--foreground2);") { oz == oz.to_i ? "#{oz.to_i} oz" : "#{oz} oz" }
            td { helpers.number_to_currency(price) }
          end
        end
      end

      span(style: "color: var(--foreground2); font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.05ch;") { "Flats (stamps)" }
      table(style: "margin-bottom: 0.5lh;") do
        USPS::PricingEngine::US_STAMP_FLAT_RATES.first(3).each do |oz, price|
          tr do
            td(style: "color: var(--foreground2);") { oz == oz.to_i ? "#{oz.to_i} oz" : "#{oz} oz" }
            td { helpers.number_to_currency(price) }
          end
        end
      end

      p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0;") do
        plain "Non-machinable: +"
        plain helpers.number_to_currency(USPS::PricingEngine::FCMI_NON_MACHINABLE_SURCHARGE)
      end
      p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0;") do
        plain "Indicia is slightly cheaper for standard letters."
      end
    end
  end

  def size_limits_card
    div("box-": "round") do
      strong { "Size Limits" }
      div("is-": "separator")

      div(class: "detail-grid") do
        span(class: "detail-label") { "Letter" }
        span { "11.5 × 6.125 in, 3.5 oz" }
        span(class: "detail-label") { "Flat" }
        span { "15 × 12 in, 13 oz" }
      end
    end
  end
end
