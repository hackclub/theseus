# frozen_string_literal: true

class Views::Letter::Queues::New < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "page-container--narrow") do
      div(class: "page-title-group content-section") do
        a(href: letter_queues_path, style: "color: var(--foreground2);") { "← Back" }
        h1(class: "page-title") { "New Queue" }
      end

      div(class: "form-card") do
        render Components::Letter::Queues::Form.new(queue: @queue)
      end
    end
  end
end
