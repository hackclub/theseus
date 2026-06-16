# frozen_string_literal: true

class Components::Shared::PageToolbar < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(title:, jumpcode_path: nil, search_path: nil, search_value: nil, search_placeholder: "Search...", search_params: {}, action_href: nil, action_label: nil, action_variant: "green")
    @title = title
    @jumpcode_path = jumpcode_path
    @search_path = search_path
    @search_value = search_value
    @search_placeholder = search_placeholder
    @search_params = search_params.compact
    @action_href = action_href
    @action_label = action_label
    @action_variant = action_variant
  end

  def view_template(&block)
    div(class: "toolbar") do
      strong(style: "font-size: 1.15em; flex-shrink: 0;") { @title }

      if @jumpcode_path
        render Components::Shared::Jumpcode.new(path: @jumpcode_path)
      end

      if @search_path
        form(action: @search_path, method: "get") do
          @search_params.each do |k, v|
            input(type: "hidden", name: k, value: v) if v.present?
          end
          input(type: "text", name: "search", placeholder: @search_placeholder, value: @search_value, class: "toolbar-search")
        end
      end

      yield if block_given?

      span(class: "spacer")

      if @action_href && @action_label
        a(href: @action_href) do
          button(class: variant_class(@action_variant)) { @action_label }
        end
      end
    end
  end

  private

  def variant_class(variant)
    case variant
    when "green" then "btn-success"
    when "red" then "btn-danger"
    when "yellow" then "btn-warning"
    when "blue" then "btn-info"
    end
  end
end
