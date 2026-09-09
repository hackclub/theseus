# frozen_string_literal: true

class Views::Letter::Queues::Edit < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: letter_queue_path(@queue), class: "link-muted") { "← #{@queue.name}" }
        strong(class: "text-title") { "Edit Queue" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        section do
          render Components::Letter::Queues::Form.new(queue: @queue)
        end
      end
      div(class: "show-sidebar") do
        section do
          strong { "Queue Info" }
          hr
          div(class: "detail-grid mt-half") do
            span(class: "detail-label") { "Slug" }
            span { @queue.slug }
            span(class: "detail-label") { "Type" }
            span { "Batch" }
            span(class: "detail-label") { "Created" }
            span { @queue.created_at.strftime("%b %-d, %Y") }
            span(class: "detail-label") { "Letters" }
            span { @queue.letters.count.to_s }
          end
        end
      end
    end
  end
end
