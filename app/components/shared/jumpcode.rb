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
        div(class: "jumpcode-popover") do
          p do
            plain "these are jumpcodes. hit "
            code { "⌘K" }
            plain ", type the code, go."
          end
          p do
            plain "letter pages: "
            jumpcode_chip("MAIL")
            plain " "
            jumpcode_chip("SCAN")
            plain " "
            jumpcode_chip("LBAT")
          end
          p do
            plain "warehouse: "
            jumpcode_chip("WORD")
            plain " "
            jumpcode_chip("SKUS")
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

  def jumpcode_chip(code)
    span(
      class: "badge jumpcode-chip",
      onclick: safe("window.openKbar?.('#{code}')"),
    ) { code }
  end
end
