class TableSync::OrderSyncJob < TableSync::TableSyncJob
  def perform(*args)
    @model = Warehouse::Order
    @sync_id = ENV["AIRTABLE_ORDER_SYNC_ID"]
    super
  end
end
