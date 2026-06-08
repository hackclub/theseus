# frozen_string_literal: true

class Components::Shared::BackButton < Components::Base
  def initialize(href:, label: "Back")
    @href = href
    @label = label
  end

  def view_template
    a(href: @href) { "← #{@label}" }
  end
end
