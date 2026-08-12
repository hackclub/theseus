# frozen_string_literal: true

class Components::Tasks::Show < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(tasks:)
    @tasks = tasks
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Your Tasks",
      jumpcode_path: tasks_path
    ) do
      form(action: refresh_tasks_path, method: "post") do
        authenticity_token_tag
        button(type: "submit", class: "btn-sm") { "⟳ Refresh" }
      end
    end

    if @tasks.empty?
      empty_state
    else
      @tasks.group_by { |t| t[:type] }.each do |type, tasks|
        task_group(type, tasks)
      end
    end
  end

  private

  def empty_state
    section(style: "text-align: center; padding: 2rem;") do
      div(style: "font-size: 2em; color: var(--green);") { "✓" }
      strong { "All clear!" }
      p(class: "text-muted", style: "margin: 0.25rem 0 0;") { "No tasks right now." }
    end
  end

  def task_group(type, tasks)
    section do
      strong { type }
      hr
      tasks.each_with_index do |task, i|
        hr if i > 0
        task_row(task)
      end
    end
  end

  def task_row(task)
    div(style: "display:flex;align-items:center;gap:0.5rem;padding:0.5rem 0;") do
      div(style: "flex:1;") do
        span(style: "font-weight:500;") { task[:name] }
        if task[:subtitle]
          whitespace
          span(class: "text-muted") { "(#{task[:subtitle]})" }
        end
      end
      a(href: task[:link]) do
        button(class: "btn-sm") { "Go →" }
      end
    end
  end

  def authenticity_token_tag
    token = helpers.form_authenticity_token
    input(type: "hidden", name: "authenticity_token", value: token)
  end
end
