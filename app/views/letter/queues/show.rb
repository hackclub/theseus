# frozen_string_literal: true

class Views::Letter::Queues::Show < Views::Letter::Queues::ShowBase
  private

  def type_label = "Batch"

  def type_badge
    span("is-": "badge", "variant-": "blue") { "Batch" }
  end

  def edit_queue_path
    edit_letter_queue_path(queue)
  end

  def queue_show_path(**params)
    letter_queue_path(queue, **params)
  end

  # --- Sidebar: Make Batch ---

  def make_batch_section
    queued_count = letter_counts.fetch("queued", 0)
    return unless queued_count > 0

    details(id: "make-batch-dialog") do
      summary(style: "list-style: none;") do
        button("variant-": "green", style: "width: 100%;") { "⊞ Make Batch" }
      end

      div(style: "margin-top: 0.5lh;") do
        form_with url: make_batch_from_letter_queue_path(queue), method: :post do |f|
          div(style: "margin-bottom: 0.5lh;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "How many letters?" }
            input(type: "text", name: "limit", style: "width: 100%;")
            small(style: "color: var(--foreground2);") { "Blank = all #{queued_count}" }
          end
          button(type: "submit", "variant-": "green", style: "width: 100%;") { "✓ Create Batch" }
        end
      end
    end
  end

  # --- Batches ---

  def batches_section
    return unless batches.any?

    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Batches" }
      span(style: "color: var(--foreground2); margin-left: 1ch;") { "(#{batches.count})" }
      div("is-": "separator")

      batches.each_with_index do |batch, i|
        batch_row(batch)
        div("is-": "separator") unless i == batches.size - 1
      end
    end
  end

  def batch_row(batch)
    row("gap-": "2", "align-": "center", style: "padding: 0.5lh 0;") do
      a(href: letter_batch_path(batch), style: "text-decoration: none;") { "Batch ##{batch.id}" }
      span(style: "color: var(--foreground2);") do
        "#{batch.letters.size} #{"letter".pluralize(batch.letters.size)}"
      end
      render Components::Shared::StatusBadge.new(status: batch.aasm_state, type: :batch)
      span(style: "flex: 1;")
      span(style: "color: var(--foreground2);") { batch.created_at.strftime("%b %d, %Y") }
    end
  end
end
