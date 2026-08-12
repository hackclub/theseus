class User
  class UpdateTasksJob < ApplicationJob
    queue_as :default

    def perform(user)
      UserTasks.new(user).warm_cache!
    end
  end
end
