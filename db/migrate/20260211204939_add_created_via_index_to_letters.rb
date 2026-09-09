# Split out of 20260211204938: letters is the biggest table in the app and
# CREATE INDEX CONCURRENTLY cannot share a transaction with the backfill.
class AddCreatedViaIndexToLetters < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :letters, :created_via, algorithm: :concurrently, if_not_exists: true
  end
end
