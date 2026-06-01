# frozen_string_literal: true

class Components::Shared::Jumpcode < Components::Base
  def initialize(code: nil, path: nil)
    @code = code || Shortcodes.code_for(path)
  end

  def view_template
    return unless @code

    span(class: "jumpcode") do
      span(
        class: "jumpcode-badge",
        title: "Press ⌘K and type #{@code}",
        onclick: safe("window.openKbar?.()")
      ) do
        span(class: "jumpcode-prefix") { "⌘K" }
        plain @code
      end

      render_help_button
    end
  end

  private

  def render_help_button
    render(Primer::Alpha::Dialog.new(
      title: "what's a jumpcode?",
      size: :small
    )) do |dialog|
      dialog.with_show_button(
        scheme: :invisible,
        size: :small,
        "aria-label": "What's a jumpcode?"
      ) do
        span(class: "jumpcode-help-trigger") { "?" }
      end

      dialog.with_body do
        div(class: "jumpcode-dialog-body") do
          p(class: "jumpcode-dialog-p") do
            plain "you've probably seen the "
            code(class: "jumpcode-code") { "⌘K #{@code}" }
            plain " badges around — those are jumpcodes. hit "
            code(class: "jumpcode-code") { "⌘K" }
            plain ", type the code, go."
          end

          p(class: "jumpcode-dialog-p") do
            plain "letter pages start with L ("
            code(class: "jumpcode-code") { "MAIL" }
            plain ", "
            code(class: "jumpcode-code") { "SCAN" }
            plain ", "
            code(class: "jumpcode-code") { "LBAT" }
            plain "), warehouse starts with W ("
            code(class: "jumpcode-code") { "WORD" }
            plain ", "
            code(class: "jumpcode-code") { "SKUS" }
            plain "). you'll pick them up fast."
          end

          p(class: "jumpcode-dialog-p--last") do
            plain "the palette also does search — "
            code(class: "jumpcode-code") { "?l" }
            plain " for letters, "
            code(class: "jumpcode-code") { "?w" }
            plain " for orders — and you can paste IDs like "
            code(class: "jumpcode-code") { "ltr!abc123" }
            plain " to jump to them."
          end
        end
      end
    end
  end
end
