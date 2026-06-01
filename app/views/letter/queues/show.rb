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
      render Primer::Alpha::Dialog.new(
        title: "Make Batch",
        subtitle: "Create a batch from queued letters",
        size: :medium,
        id: "make-batch-dialog"
      ) do |dialog|
        dialog.with_show_button(scheme: :primary, size: :medium) do |btn|
          btn.with_leading_visual_icon(icon: :package)
          "Make Batch"
        end

        form_with url: make_batch_from_letter_queue_path(queue), method: :post do |f|
          render(Primer::Alpha::Dialog::Body.new) do
            render(Primer::Alpha::TextField.new(
              name: "limit",
              label: "How many letters to batch?",
              caption: "Leave blank to batch all #{queued_count} queued letters"
            ))
          end

          render(Primer::Alpha::Dialog::Footer.new(show_divider: true)) do
            render(Primer::Beta::Button.new(data: { "close-dialog-id": "make-batch-dialog" })) { "Cancel" }
            render(Primer::Beta::Button.new(scheme: :primary, type: :submit)) { "Make Batch" }
          end
        end
      end
    end
  end

  # --- Batches ---

  def batches_section
    return unless batches.any?

    collapsible_section("Batches", batches.count) do
      render Primer::Beta::BorderBox.new do |box|
        batches.each do |batch|
          box.with_row do
            batch_row(batch)
          end
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
