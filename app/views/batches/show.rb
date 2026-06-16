# frozen_string_literal: true

class Views::Batches::Show < Views::Base
  def initialize(batch:)
    @batch = batch
  end

  def view_template
    toolbar
    render @batch

    if @batch.is_a?(Letter::Batch) && @batch.processed?
      render partial: "letter_batch", locals: { batch: @batch }

      if @batch.letters.any?
        render partial: "letters_collection", locals: { letters: @batch.letters }
      end
    end

    if @batch.is_a?(Warehouse::Batch) && @batch.orders.any?
      render partial: "orders_collection", locals: { orders: @batch.orders }
    end

    render partial: "admin_inspector", locals: { record: @batch }

    if @batch.addresses.any?
      render partial: "addresses_table", locals: { addresses: @batch.addresses }
    end

    danger_zone
  end

  private

  attr_reader :batch

  def toolbar
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: batches_path, style: "text-decoration: none; color: GrayText;") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "#{@batch.type.split('::').first.titleize} Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      span(class: "spacer")
      a(href: edit_batch_path(@batch)) { "✎ Edit" }
    end
  end

  def danger_zone
    section(style: "margin-bottom: 1rem; border-color: var(--red);") do
      strong { "Danger Zone" }
      hr
      div(style: "margin-top: 0.5rem;") do
        span(style: "color: GrayText;") { "This action cannot be undone." }
        div(style: "margin-top: 0.5rem;") do
          form(id: "delete-batch-form", method: :post, action: batch_path(@batch), style: "display: none;") do
            input(type: :hidden, name: :_method, value: :delete)
            input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          end
          button(
            type: :submit,
            class: "btn-danger btn-sm",
            form: "delete-batch-form"
          ) { "✕ Delete Batch" }
        end
      end
    end
  end
end
