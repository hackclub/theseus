class AddMissingPerformanceIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :letter_queues, :slug, unique: true, algorithm: :concurrently, if_not_exists: true
    add_index :letters, :indicia_state, algorithm: :concurrently, if_not_exists: true

    # Deduplicate before adding the unique index — dev/staging may have
    # slipped past the model-level validation. Delete dependent rows first.
    dupes_sql = <<~SQL.squish
      SELECT id FROM public_users
      WHERE id NOT IN (SELECT MIN(id) FROM public_users GROUP BY email)
    SQL

    execute "DELETE FROM public_login_codes WHERE user_id IN (#{dupes_sql})"
    execute "DELETE FROM public_api_keys WHERE public_user_id IN (#{dupes_sql})"
    execute "DELETE FROM public_users WHERE id IN (#{dupes_sql})"

    add_index :public_users, :email, unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
