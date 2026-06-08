# frozen_string_literal: true

class Views::Letter::Queues::Edit < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: letter_queue_path(@queue), style: "text-decoration: none; color: var(--foreground2);") { "← #{@queue.name}" }
        strong(style: "font-size: 1.15em;") { "Edit Queue" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        div("box-": "round") do
          render Components::Letter::Queues::Form.new(queue: @queue)
        end
      end
      div(class: "show-sidebar") do
        div("box-": "round") do
          strong { "Queue Info" }
          div("is-": "separator")
          div(class: "detail-grid", style: "margin-top: 0.5lh;") do
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
