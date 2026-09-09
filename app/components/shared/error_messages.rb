# frozen_string_literal: true

class Components::Shared::ErrorMessages < Components::Base
  def initialize(record:)
    @record = record
  end

  def view_template
    return if @record.errors.none?

    div(class: "banner banner-error") do
      strong { "#{@record.errors.count} #{"error".pluralize(@record.errors.count)}:" }
      ul do
        @record.errors.full_messages.each { |msg| li { msg } }
      end
    end
  end
end
