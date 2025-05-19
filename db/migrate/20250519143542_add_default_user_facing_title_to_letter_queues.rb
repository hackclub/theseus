class AddDefaultUserFacingTitleToLetterQueues < ActiveRecord::Migration[8.0]
  def up
    # Set user_facing_title to name for all existing queues where user_facing_title is nil
    Letter::Queue.where(user_facing_title: nil).find_each do |queue|
      queue.update_column(:user_facing_title, queue.name)
    end
  end

  def down
    # No need to revert the data changes as it's just setting defaults
  end
end
