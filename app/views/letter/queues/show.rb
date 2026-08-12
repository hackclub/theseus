# frozen_string_literal: true

class Views::Letter::Queues::Show < Views::Letter::Queues::ShowBase
  private

  def type_label = "Batch"

  def type_badge
    span(class: "badge badge-info") { "Batch" }
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
        button(class: "btn-success", style: "width: 100%;") { "⊞ Make Batch" }
      end

      div(style: "margin-top: 0.5rem;") do
        form_with url: make_batch_from_letter_queue_path(queue), method: :post do |f|
          div(style: "margin-bottom: 0.5rem;") do
            label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25rem;") { "How many letters?" }
            input(type: "text", name: "limit", style: "width: 100%;")
            small(class: "text-muted") { "Blank = all #{queued_count}" }
          end
          button(type: "submit", class: "btn-success", style: "width: 100%;") { "✓ Create Batch" }
        end
      end
    end
  end

  # --- Batches ---

  def batches_section
    return unless batches.any?

    section(style: "margin-bottom: 1rem;") do
      strong { "Batches" }
      span(class: "text-muted", style: "margin-left: 0.5rem;") { "(#{batches.count})" }
      hr

      table do
        thead do
          tr do
            th { "Batch" }
            th { "Letters" }
            th { "Date" }
            th { "Status" }
          end
        end
        tbody do
          batches.each do |batch|
            tr do
              td do
                a(href: letter_batch_path(batch), style: "text-decoration: none;") { "Batch ##{batch.id}" }
              end
              td { plain "#{batch.letters.size}" }
              td(class: "text-muted") { batch.created_at.strftime("%b %-d, %Y") }
              td { render Components::Shared::StatusBadge.new(status: batch.aasm_state, type: :batch) }
            end
          end
        end
      end
    end
  end
end
