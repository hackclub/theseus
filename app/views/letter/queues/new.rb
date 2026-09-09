# frozen_string_literal: true

class Views::Letter::Queues::New < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: letter_queues_path, class: "link-muted") { "← Queues" }
        strong(class: "text-title") { "New Batch Queue" }
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
          strong { "Help" }
          hr
          div(class: "mt-half text-muted help-text") do
            p { "Batch queues collect letters and let you create batches for bulk processing and printing." }
            p { "You'll need a return address and mailer ID configured before sending." }
          end
        end
      end
    end
  end
end
