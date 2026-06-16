# frozen_string_literal: true

class Views::Letters::New < Views::Base
  def initialize(letter:)
    @letter = letter
  end

  def view_template
    div(style: "display:flex;align-items:center;gap:0.5rem;margin-bottom:1rem;") do
      a(href: letters_path, style: "text-decoration:none;color:GrayText;") { "← Letters" }
      strong(style: "font-size:1.15em;") { "New Letter" }
    end

    render Components::Letters::Form.new(letter: @letter)
  end
end
