# frozen_string_literal: true

class Components::Shared::StatFilters < Components::Base
  def initialize(stats:, active:, base_path:, filter_key: :status, preserved_params: {}, total: nil)
    @stats = stats
    @active = active
    @base_path = base_path
    @filter_key = filter_key
    @preserved_params = preserved_params.compact
    @total = total
  end

  def view_template
    div(class: "stat-filters") do
      @stats.each do |stat|
        render_chip(stat)
      end
      if @total
        span(class: "stat-total") { "#{format_number(@total)} total" }
      end
    end
  end

  private

  def render_chip(stat)
    is_active = @active == stat[:param]
    color = stat[:color] ? "var(--#{stat[:color]})" : "var(--foreground1)"
    params = @preserved_params.dup
    params[@filter_key] = stat[:param] unless is_active

    a(href: @base_path.call(**params), class: "stat-filter #{'active' if is_active}") do
      span(class: "stat-count", style: "color: #{color};") { format_number(stat[:count]) }
      span(class: "stat-label") { stat[:label] }
    end
  end

  def format_number(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
