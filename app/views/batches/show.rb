# frozen_string_literal: true

class Views::Batches::Show < Views::Base
  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        a(href: batches_path, style: "text-decoration: none; color: var(--foreground2);") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "#{@batch.type.split('::').first.titleize} Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      div(class: "toolbar-spacer")
      a(href: edit_batch_path(@batch), "size-": "small") { "✎ Edit" }
    end

    # Main batch display (render the existing _batch partial)
    render @batch

    # Letter batch details for Letter::Batch
    if @batch.is_a?(Letter::Batch) && @batch.processed?
      render partial: "letter_batch", locals: { batch: @batch }

      if @batch.letters.any?
        collapsible_section("Letters", @batch.letters.count) do
          render partial: "letters_collection", locals: { letters: @batch.letters }
        end
      end
    end

    # Warehouse orders for Warehouse::Batch
    if @batch.is_a?(Warehouse::Batch) && @batch.orders.any?
      collapsible_section("Orders", @batch.orders.count) do
        render partial: "orders_collection", locals: { orders: @batch.orders }
      end
    end

    # Admin inspector
    render partial: "admin_inspector", locals: { record: @batch }

    # Addresses table
    if @batch.addresses.any?
      collapsible_section("Addresses", @batch.addresses.count) do
        render partial: "addresses_table", locals: { addresses: @batch.addresses }
      end
    end

    # Danger zone
    danger_zone
  end

  private

  attr_reader :batch

  def collapsible_section(title, count)
    details(style: "margin-top: 1lh;") do
      summary(style: "cursor: pointer; display: flex; align-items: center; justify-content: space-between;") do
        strong { "#{title} (#{count})" }
        span(style: "color: var(--foreground2);") { "▼" }
      end
      div(style: "margin-top: 0.5lh;") do
        yield
      end
    end
  end

  def danger_zone
    div("box-": "round", style: "margin-top: 2lh; border-color: var(--red);") do
      strong { "Danger Zone" }
      div("is-": "separator")
      p(style: "color: var(--foreground2); margin: 0 0 0.5lh 0;") { "This action cannot be undone." }
      button(
        type: :submit,
        "variant-": "red",
        form: "delete-batch-form"
      ) { "✕ Delete this batch" }
      form(id: "delete-batch-form", method: :post, action: batch_path(@batch), style: "display: none;") do
        input(type: :hidden, name: :_method, value: :delete)
        input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
      end
    end
  end
end
