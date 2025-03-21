class TableSync::TableSyncJob < ApplicationJob
  queue_as :default
  def perform(*args)
    unless @sync_id
      Rails.logger.warn("no sync id for #{self.class.name}!")
      return
    end
    @model&.mirror_to_airtable!(@sync_id)
  end
end
