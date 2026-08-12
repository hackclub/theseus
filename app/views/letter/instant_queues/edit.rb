# frozen_string_literal: true

class Views::Letter::InstantQueues::Edit < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: letter_instant_queue_path(@queue), style: "text-decoration: none; color: var(--foreground2);") { "← #{@queue.name}" }
        strong(style: "font-size: 1.15em;") { "Edit Queue" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        section do
          render Components::Letter::InstantQueues::Form.new(queue: @queue)
        end
      end
      div(class: "show-sidebar") do
        section do
          strong { "Queue Info" }
          hr
          div(class: "detail-grid", style: "margin-top: 0.5rem;") do
            span(class: "detail-label") { "Slug" }
            span { @queue.slug }
            span(class: "detail-label") { "Type" }
            span { "Instant" }
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
