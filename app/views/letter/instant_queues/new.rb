# frozen_string_literal: true

class Views::Letter::InstantQueues::New < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "page-container--narrow") do
      div(class: "page-title-group mb-3") do
        a(href: letter_queues_path, style: "color: var(--foreground2);") { "← Back" }
        h1(class: "page-title") { "New Instant Queue" }
      end

      div(class: "form-card") do
        render Components::Letter::InstantQueues::Form.new(queue: @queue)
      end
    end
  end
end
