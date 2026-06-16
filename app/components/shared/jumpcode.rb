# frozen_string_literal: true

class Components::Shared::Jumpcode < Components::Base
  def initialize(code: nil, path: nil)
    @code = code || Shortcodes.code_for(path)
  end

  def view_template
    return unless @code

    div(style: "display:flex;gap:0.5rem;align-items:center", class: "jumpcode") do
      span(
        class: "badge",
        title: "Press ⌘K and type #{@code}",
        onclick: safe("window.openKbar?.()")
      ) do
        span(style: "color:GrayText") { "⌘K" }
        plain " #{@code}"
      end

      details(class: "popover jumpcode-help", style: "position:relative") do
        summary(tabindex: "0", class: "btn-sm") { "?" }
        div(style: "position:absolute;right:0;top:100%;padding:1rem;max-width:24rem;background:Canvas;border:1px solid var(--background2)") do
          p do
            plain "these are jumpcodes. hit "
            code { "⌘K" }
            plain ", type the code, go."
          end
          p do
            plain "letter pages: "
            span(class: "badge") { "MAIL" }
            plain " "
            span(class: "badge") { "SCAN" }
            plain " "
            span(class: "badge") { "LBAT" }
          end
          p do
            plain "warehouse: "
            span(class: "badge") { "WORD" }
            plain " "
            span(class: "badge") { "SKUS" }
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
