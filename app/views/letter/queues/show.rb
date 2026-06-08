# frozen_string_literal: true

class Views::Letter::Queues::Show < Views::Letter::Queues::ShowBase
  private

  def type_label = "Batch"

  def edit_queue_path
    edit_letter_queue_path(queue)
  end

  def queue_show_path(**params)
    letter_queue_path(queue, **params)
  end

  # --- Make Batch ---

  def make_batch_section
    return unless letter_counts.fetch("queued", 0) > 0

    render_make_batch_dialog
  end

  def render_make_batch_dialog
    queued_count = letter_counts.fetch("queued", 0)

    div(class: "content-section") do
      details(id: "make-batch-dialog") do
        summary do
          button("variant-": "green") { "⊞ Make Batch" }
        end

        div("box-": "round", style: "margin-top: 1lh; padding: 1lh 2ch;") do
          h3(style: "margin: 0;") { "Make Batch" }
          p(style: "color: var(--foreground2);") { "Create a batch from queued letters" }
          div("is-": "separator")

          form_with url: make_batch_from_letter_queue_path(queue), method: :post do |f|
            div(style: "margin-bottom: 1lh;") do
              label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "How many letters to batch?" }
              input(type: "text", name: "limit", style: "width: 100%;")
              small(style: "color: var(--foreground2);") { "Leave blank to batch all #{queued_count} queued letters" }
            end

            tag("row", "gap-": "1", style: "justify-content: flex-end;") do
              button(type: "submit", "variant-": "green") { "✓ Make Batch" }
            end
          end
        end
      end
    end
  end

  # --- Batches ---

  def batches_section
    return unless batches.any?

    collapsible_section("Batches", batches.count) do
      div("box-": "round") do
        batches.each_with_index do |batch, i|
          batch_row(batch)
          div("is-": "separator") unless i == batches.size - 1
        end
      end
    end
  end

  def batch_row(batch)
    div(class: "queue-batch-row") do
      a(href: letter_batch_path(batch), class: "accent-link") do
        "Batch ##{batch.id}"
      end
      span(class: "text-sm kv-label") do
        "#{batch.letters.size} #{"letter".pluralize(batch.letters.size)}"
      end
      render Components::Shared::StatusBadge.new(status: batch.aasm_state, type: :batch)
      span(class: "flex-1")
      span(class: "text-sm kv-label") do
        batch.created_at.strftime("%b %d, %Y")
      end
    end
  end
end
