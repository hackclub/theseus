# Columns, the FK and the backfill only — this migration stays transactional.
# The indexes are built concurrently in 20260123084629, which cannot run
# inside a transaction.
class AddCreatedViaToWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    # These columns were added to db/schema.rb without a migration file, so a
    # database may already have them while missing the schema_migrations row.
    # Every step is guarded, and the backfill only runs for the columns this
    # migration actually created.
    created_via_added = false
    origin_batch_added = false

    unless column_exists?(:warehouse_orders, :created_via)
      add_column :warehouse_orders, :created_via, :integer, null: false, default: 0
      created_via_added = true
    end

    unless column_exists?(:warehouse_orders, :origin_batch_id)
      add_column :warehouse_orders, :origin_batch_id, :bigint
      origin_batch_added = true
    end

    # NOT VALID first: warehouse_orders is large, and validating the
    # constraint while holding the lock from ADD CONSTRAINT would block writes
    # for the length of a full scan. VALIDATE takes a weaker lock.
    unless foreign_key_exists?(:warehouse_orders, :batches, column: :origin_batch_id)
      add_foreign_key :warehouse_orders, :batches, column: :origin_batch_id, validate: false
    end

    reversible do |dir|
      dir.up do
        if created_via_added || origin_batch_added
          set = []
          set << "created_via = CASE WHEN batch_id IS NOT NULL THEN 1 ELSE 0 END" if created_via_added
          set << "origin_batch_id = batch_id" if origin_batch_added

          execute "UPDATE warehouse_orders SET #{set.join(', ')}"
        end

        # No-op if it is already validated.
        validate_foreign_key :warehouse_orders, :batches, column: :origin_batch_id
      end
    end
  end
end
