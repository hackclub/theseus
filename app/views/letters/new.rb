# frozen_string_literal: true

class Views::Letters::New < Views::Base
  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(class: "flex-row mb-1") do
      a(href: letters_path, class: "link-muted") { "← Letters" }
      strong(class: "text-title") { "New Letter" }
    end

    render Components::Letters::Form.new(letter: @letter)
  end
end
