Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.enable_cron = true
  config.good_job.execution_mode = :async

  config.good_job.cron = {
    update_mailing_info: {
      cron: "*/5 * * * *",
      class: "Warehouse::UpdateMailingInfoJob"
    },
    update_median_postage_costs: {
      cron: "*/30 * * * *",
      class: "Warehouse::UpdateMedianPostageCostsJob"
    },
    update_inventory_levels: {
      cron: "*/5 * * * *",
      class: "Warehouse::UpdateInventoryLevelsJob"
    },
    update_cancellations: {
      cron: "*/10 * * * *",
      class: "Warehouse::UpdateCancellationsJob"
    },
    sync_skus: {
      cron: "*/7 * * * *",
      class: "TableSync::SKUSyncJob"
    },
    sync_orders: {
      cron: "*/8 * * * *",
      class: "TableSync::OrderSyncJob"
    }
  }
end
