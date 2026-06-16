# frozen_string_literal: true

class Views::Letter::InstantQueues::New < Views::Base
  def initialize(queue:)
    @queue = queue
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: letter_queues_path, style: "text-decoration: none; color: GrayText;") { "← Queues" }
        strong(style: "font-size: 1.15em;") { "New Instant Queue" }
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
          div(style: "margin-top: 0.5rem;", class: "text-muted") do
            p(style: "margin: 0 0 0.5rem;") { "Instant queues process letters individually via the API — each letter is printed and mailed as soon as it arrives." }
            p(style: "margin: 0;") { "Configure a template, postage type, and payment account for automatic processing." }
          end
        end
      end
    end
  end
end
