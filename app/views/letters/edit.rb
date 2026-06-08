# frozen_string_literal: true

class Views::Letters::Edit < Views::Base
  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: letter_path(@letter), style: "text-decoration: none; color: var(--foreground2);") { "← #{@letter.public_id}" }
        strong(style: "font-size: 1.15em;") { "Edit Letter" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        render Components::Letters::Form.new(letter: @letter)
      end

      div(class: "show-sidebar") do
        letter_info_card
      end
    end
  end

  private

  def letter_info_card
    div("box-": "round") do
      strong { "Letter Info" }
      div("is-": "separator")

      div(class: "detail-grid") do
        span(class: "detail-label") { "ID" }
        span { code { @letter.public_id } }
        span(class: "detail-label") { "Status" }
        span { render Components::Shared::StatusBadge.new(status: @letter.aasm_state, type: :letter) }
        span(class: "detail-label") { "Created" }
        span { @letter.created_at.strftime("%b %-d, %Y") }
        span(class: "detail-label") { "Origin" }
        span { @letter.origin_label }
      end
    end
  end
end
