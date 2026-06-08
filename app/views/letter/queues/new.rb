# frozen_string_literal: true

class Views::Letter::Queues::New < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: letter_queues_path, style: "text-decoration: none; color: var(--foreground2);") { "← Queues" }
        strong(style: "font-size: 1.15em;") { "New Batch Queue" }
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
          strong { "Help" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh; color: var(--foreground2);") do
            p(style: "margin: 0 0 0.5lh;") { "Batch queues collect letters and let you create batches for bulk processing and printing." }
            p(style: "margin: 0;") { "You'll need a return address and mailer ID configured before sending." }
          end
        end
      end
    end
  end
end
