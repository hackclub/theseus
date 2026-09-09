# frozen_string_literal: true

class Views::Letter::InstantQueues::New < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: letter_queues_path, class: "link-muted") { "← Queues" }
        strong(class: "text-title") { "New Instant Queue" }
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
          strong { "Help" }
          hr
          div(class: "mt-half text-muted help-text") do
            p { "Instant queues process letters individually via the API — each letter is printed and mailed as soon as it arrives." }
            p { "Configure a template, postage type, and payment account for automatic processing." }
          end
        end
      end
    end
  end
end
