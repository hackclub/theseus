class UpdateTagCacheJob < ApplicationJob
  queue_as :default

  def perform
    Rails.cache.delete("available_tags")
    ApplicationController.helpers.available_tags
  end
end 