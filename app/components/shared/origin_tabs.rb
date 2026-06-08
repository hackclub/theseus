# frozen_string_literal: true

class Components::Shared::OriginTabs < Components::Base
  def initialize(options:, active:, base_path:, filter_key: :origin, preserved_params: {})
    @options = options
    @active = active
    @base_path = base_path
    @filter_key = filter_key
    @preserved_params = preserved_params.compact
  end

  def view_template
    div(class: "origin-tabs") do
      @options.each do |key, label|
        params = @preserved_params.dup
        params[@filter_key] = key

        a(
          href: @base_path.call(**params),
          class: @active == key ? "active" : nil
        ) { label }
      end
    end
  end
end
