module Taggable
  extend ActiveSupport::Concern

  included do
    taggable_array :tags
    before_save :zap_empty_tags
    after_save :update_tag_cache, if: :saved_change_to_tags?
  end

  def zap_empty_tags
    tags.reject!(&:blank?)
  end

  private

  def update_tag_cache
    UpdateTagCacheJob.perform_later
  end
end