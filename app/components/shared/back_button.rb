# frozen_string_literal: true

class Components::Shared::BackButton < Components::Base
  def initialize(href:, label: "Back")
    @href = href
    @label = label
  end

  def view_template
    render Primer::Beta::Button.new(tag: :a, href: @href, scheme: :secondary) do |btn|
      btn.with_leading_visual_icon(icon: :"arrow-left")
      @label
    end
  end
end
