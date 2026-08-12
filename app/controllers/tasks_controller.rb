class TasksController < ApplicationController
  skip_after_action :verify_authorized

  def show
    render Components::Tasks::Show.new(tasks: user_tasks.all_cached)
  end

  def badge
    @count = user_tasks.count_cached
    render :badge, layout: false
  end

  def refresh
    user_tasks.warm_cache!
    redirect_to tasks_path
  end

  private

  def user_tasks = @user_tasks ||= UserTasks.new(current_user)
end
