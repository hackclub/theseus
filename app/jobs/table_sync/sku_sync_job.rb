class TableSync::SKUSyncJob < TableSync::TableSyncJob
  def perform(*args)
    @model = Warehouse::SKU
    @sync_id = ENV["AIRTABLE_SKU_SYNC_ID"]
    super
  end
end
