# frozen_string_literal: true

class Views::Letters::Edit < Views::Base
  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(class: "page-container") do
      div(class: "page-title-group content-section") do
        a(href: letter_path(@letter), style: "color: var(--foreground2);") { "← Back" }
        h1(class: "page-title") { "Editing letter" }
      end

      div(class: "batch-layout") do
        div do
          render Components::Letters::Form.new(letter: @letter)
        end

        div(class: "sticky-sidebar") do
          letter_info_card
        end
      end
    end
  end

  private

  def letter_info_card
    div("box-": "round") do
      h3(style: "margin: 0;") { "Letter Info" }
      div("is-": "separator")
      dl(class: "edit-info-dl") do
        dt { "ID" }
        dd do
          code { @letter.public_id }
        end

        dt { "Status" }
        dd do
          render Components::Shared::StatusBadge.new(status: @letter.aasm_state, type: :letter)
        end

        dt { "Created" }
        dd { @letter.created_at.strftime("%b %-d, %Y") }

        dt { "Origin" }
        dd { @letter.origin_label }
      end
    end
  end
end
