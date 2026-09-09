# Split out of 20260123084628 so the index builds can run concurrently:
# CREATE INDEX CONCURRENTLY cannot run inside a transaction, and a plain
# CREATE INDEX on warehouse_orders would hold a write lock for its duration.
#
# if_not_exists: true because these indexes already exist wherever the columns
# were added by hand. If a concurrent build is interrupted Postgres leaves an
# INVALID index behind; drop it before re-running.
class AddCreatedViaIndexesToWarehouseOrders < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :warehouse_orders, :created_via, algorithm: :concurrently, if_not_exists: true
    add_index :warehouse_orders, :origin_batch_id, algorithm: :concurrently, if_not_exists: true
  end
end
