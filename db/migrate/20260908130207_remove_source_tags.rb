# Source tags are gone from the application, but main's still-running code
# reads source_tags and the source_tag_id columns during the rollout. Dropping
# them here would break every old process still serving traffic.
#
# So this migration only does the half that is safe to run while old code is
# live: it makes the columns nullable, because new code never sets them. The
# destructive half lives in db/deferred_migrations/20260910000000_drop_source_tags.rb
# and is run after the deploy has fully rolled out.
class RemoveSourceTags < ActiveRecord::Migration[8.0]
  def change
    change_column_null :warehouse_orders, :source_tag_id, true if column_exists?(:warehouse_orders, :source_tag_id)
    change_column_null :warehouse_templates, :source_tag_id, true if column_exists?(:warehouse_templates, :source_tag_id)
  end
end
