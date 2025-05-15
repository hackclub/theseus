class TasksController < ApplicationController
  skip_after_action :verify_authorized
  before_action :find_tasks

  def badge
    render :badge, layout: false
  end

  def show
    render :show
  end

  def refresh
    User::UpdateTasksJob.perform_now(current_user)
    redirect_to tasks_path
  end

  def find_tasks
    @tasks = Rails.cache.read("user_tasks/#{current_user.id}")
    @tasks ||= User::UpdateTasksJob.perform_now(current_user)
  end
end
