# frozen_string_literal: true

class Components::Shared::Jumpcode < Components::Base
  def initialize(code: nil, path: nil)
    @code = code || Shortcodes.code_for(path)
  end

  def view_template
    return unless @code

    row( "gap-": "1", "align-": "center", class: "jumpcode") do
      span(
        "is-": "badge", "variant-": "background2",
        title: "Press ⌘K and type #{@code}",
        onclick: safe("window.openKbar?.()")
      ) do
        span(style: "color: var(--foreground2);") { "⌘K" }
        plain " #{@code}"
      end

      details("is-": "popover", "position-": "bottom baseline-right", class: "jumpcode-help") do
        summary(tabindex: "0", size: "small") { "?" }
        div(style: "padding: 1lh 1ch; max-width: 48ch;") do
          p do
            plain "these are jumpcodes. hit "
            code { "⌘K" }
            plain ", type the code, go."
          end
          p do
            plain "letter pages: "
            span("is-": "badge", "variant-": "background2") { "MAIL" }
            plain " "
            span("is-": "badge", "variant-": "background2") { "SCAN" }
            plain " "
            span("is-": "badge", "variant-": "background2") { "LBAT" }
          end
          p do
            plain "warehouse: "
            span("is-": "badge", "variant-": "background2") { "WORD" }
            plain " "
            span("is-": "badge", "variant-": "background2") { "SKUS" }
          end
          p do
            plain "also try "
            code { "?l" }
            plain " (search letters) or "
            code { "ltr!abc" }
            plain " (jump to ID)"
          end
        end
      end
    end
  end
end
