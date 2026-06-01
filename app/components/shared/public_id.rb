# frozen_string_literal: true

class Components::Shared::PublicId < Components::Base
  def initialize(value:, tooltip_direction: "n")
    @value = value
    @tooltip_direction = tooltip_direction
  end

  def view_template
    span(
      class: "pointer tooltipped tooltipped--#{@tooltip_direction} public-id",
      aria_label: "click to copy...",
      data_copy_to_clipboard: @value
    ) do
      plain @value
      whitespace
      render Primer::Beta::Octicon.new(icon: :copy, size: :small, color: :muted)
    end
  end
end
