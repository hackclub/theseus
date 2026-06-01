# frozen_string_literal: true

class Views::Batches::Show < Views::Base
  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(
        title: "#{@batch.type.split('::').first.titleize} Batch ##{@batch.id}",
        subtitle: "#{pluralize(@batch.addresses.count, @batch.type.split('::').first.downcase)}"
      ) do |header|
        header.with_actions do
          render Primer::Beta::Button.new(tag: :a, href: batches_path, scheme: :secondary, size: :small) do |btn|
            btn.with_leading_visual_icon(icon: :"arrow-left")
            "Back to batches"
          end
          render Primer::Beta::Button.new(tag: :a, href: edit_batch_path(@batch), scheme: :secondary, size: :small) do |btn|
            btn.with_leading_visual_icon(icon: :pencil)
            "Edit"
          end
        end
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
  end

  private

  attr_reader :batch

  def collapsible_section(title, count)
    details(class: "collapsible-section-mt") do
      summary(class: "collapsible-summary collapsible-summary--flex") do
        h2(class: "section-heading-lg m-0") { "#{title} (#{count})" }
        span(class: "kv-label") { "▼" }
      end
      div(class: "collapsible-body collapsible-body--padded") do
        yield
      end
    end
  end

  def danger_zone
    div(class: "danger-zone") do
      h3 { "Danger Zone" }
      p(class: "danger-zone-desc") { "This action cannot be undone." }
      render Primer::Beta::Button.new(
        tag: :button,
        scheme: :danger,
        form: "delete-batch-form",
        type: :submit
      ) do |btn|
        btn.with_leading_visual_icon(icon: :trash)
        "Delete this batch"
      end
      form(id: "delete-batch-form", method: :post, action: batch_path(@batch), class: "form-inline") do
        input(type: :hidden, name: :_method, value: :delete)
        input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
      end
    end
  end
end
