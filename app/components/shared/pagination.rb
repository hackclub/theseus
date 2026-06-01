# frozen_string_literal: true

class Components::Shared::Pagination < Components::Base
  def initialize(collection:, base_path:, filter_params: {})
    @collection = collection
    @base_path = base_path
    @filter_params = filter_params.compact
  end

  def view_template
    return unless collection.respond_to?(:total_pages) && collection.total_pages > 1

    current = collection.current_page
    total = collection.total_pages

    nav(class: "pagination") do
      if current > 1
        a(href: page_path(1), class: "pagination-link") { "« First" }
        a(href: page_path(current - 1), class: "pagination-link") { "‹ Prev" }
      end

      window(current, total).each do |page_num|
        if page_num == :gap
          span(class: "pagination-gap") { "…" }
        elsif page_num == current
          span(class: "pagination-current") { page_num.to_s }
        else
          a(href: page_path(page_num), class: "pagination-link") { page_num.to_s }
        end
      end

      if current < total
        a(href: page_path(current + 1), class: "pagination-link") { "Next ›" }
        a(href: page_path(total), class: "pagination-link") { "Last »" }
      end
    end
  end

  private

  attr_reader :collection, :base_path, :filter_params

  def page_path(page)
    base_path.call(**filter_params, page: page)
  end

  def window(current, total, size: 2)
    pages = []
    ([1, current - size].max..[current + size, total].min).each { |p| pages << p }
    pages.unshift(1) unless pages.include?(1)
    pages.push(total) unless pages.include?(total)
    result = []
    pages.each_with_index do |p, i|
      result << :gap if i > 0 && p > pages[i - 1] + 1
      result << p
    end
    result
  end
end
