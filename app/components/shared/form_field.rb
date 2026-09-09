# frozen_string_literal: true

class Components::Shared::FormField < Components::Base
  def initialize(label:, name: nil, value: nil, required: false, type: "text", hint: nil, input: true)
    @label = label
    @name = name
    @value = value
    @required = required
    @type = type
    @hint = hint
    @input = input
  end

  def view_template(&block)
    div(class: "form-field") do
      label(class: "form-field-label") do
        plain @label
        span(class: "text-danger") { " *" } if @required
      end
      if block
        yield
      elsif @input && @name
        coerced = @value.is_a?(BigDecimal) ? "%.2f" % @value : @value
        attrs = { type: @type, name: @name, value: coerced, required: @required, class: "form-field-input" }
        attrs[:step] = "0.01" if @type == "number"
        input(**attrs)
      end
      if @hint
        small(class: "form-field-hint text-muted") { @hint }
      end
    end
  end
end
