module Taggable
  extend ActiveSupport::Concern

  included do
    taggable_array :tags
    before_save :zap_empty_tags
  end

  def zap_empty_tags
    tags.reject!(&:blank?)
  end
end