# frozen_string_literal: true

class Views::Letters::Edit < Views::Base
  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(class: "page-container") do
      div(class: "page-title-group content-section") do
        render Primer::Beta::Button.new(tag: :a, href: letter_path(@letter), scheme: :invisible, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back"
        end
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
    render Primer::Beta::BorderBox.new do |box|
      box.with_header do |header|
        header.with_title(tag: :h3) { "Letter Info" }
      end
      box.with_body do
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
end
