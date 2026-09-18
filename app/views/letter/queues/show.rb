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

  def api_endpoint_url = api_v1_letter_queue_url(queue)

  def api_endpoint_path = api_v1_letter_queue_path(queue)

  # --- Sidebar: Make Batch ---

  def make_batch_section
    queued_count = letter_counts.fetch("queued", 0)
    return unless queued_count > 0

    details(id: "make-batch-dialog") do
      summary(tabindex: "0", class: "summary-plain btn-success w-100") { "⊞ Make Batch" }

      div(class: "mt-half") do
        form_with url: make_batch_from_letter_queue_path(queue), method: :post do |f|
          div(class: "mb-half") do
            label(class: "form-field-label") { "How many letters?" }
            input(type: "text", name: "limit", class: "w-100")
            small(class: "text-muted") { "Blank = all #{queued_count}" }
          end
          button(type: "submit", class: "btn-success w-100") { "✓ Create Batch" }
        end
      end
    end
  end

  # --- Batches ---

  def batches_section
    return unless batches.any?

    section(class: "mb-1") do
      strong { "Batches" }
      span(class: "text-muted ml-half") { "(#{batches.count})" }
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
                a(href: letter_batch_path(batch), class: "no-underline") { "Batch ##{batch.id}" }
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
