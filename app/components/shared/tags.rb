# frozen_string_literal: true

class Components::Shared::Tags < Components::Base
  def initialize(tags:)
    @tags = tags
  end

  def view_template
    return if tags.blank?

    div(class: "tags-list") do
      tags.compact_blank.each do |tag|
        a(href: tag_stats_path(tag), class: "link-reset") do
          span(class: "badge badge-info") { tag }
        end
      end
    end
  end

  private

  attr_reader :tags
end
