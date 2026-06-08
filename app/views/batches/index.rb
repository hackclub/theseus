# frozen_string_literal: true

class Views::Batches::Index < Views::Base
  def initialize(batches:)
    @batches = batches
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(title: "Batches", subtitle: "#{@batches.count} batches") do |header|
        header.with_actions do
          a(href: new_batch_path) { "+ Upload CSV" }
        end
      end

      if @batches.any?
        batches_grid
      else
        blankslate
      end
    end
  end

  private

  attr_reader :batches

  def batches_grid
    div("box-": "round") do
      @batches.each_with_index do |batch, i|
        div("is-": "separator") if i > 0
        div(style: "padding: 0.5lh 2ch;") { batch_row(batch) }
      end
    end
  end

  def batch_row(batch)
    div(class: "batch-index-row") do
      # Left side: batch info
      div(class: "batch-index-row-main") do
        div(class: "batch-index-row-title") do
          h3(class: "section-heading-lg") do
            "#{batch.type.split('::').first.titleize} Batch ##{batch.id}"
          end
          render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch)
        end

        # Tags
        if batch.tags.any?
          div(class: "mb-2") do
            render Components::Shared::Tags.new(tags: batch.tags)
          end
        end

        # Metadata
        div(class: "index-card-meta") do
          span do
            strong { "Type: " }
            plain batch.type.split('::').first.titleize
          end
          span do
            strong { "Created: " }
            plain time_ago_in_words(batch.created_at)
            plain " ago"
          end
          span do
            strong { "Addresses: " }
            plain batch.addresses.count
          end
        end
      end

      # Right side: action button
      div(class: "batch-index-row-actions") do
        a(href: batch_path(batch), "size-": "small") { "View Details →" }
      end
    end
  end

  def blankslate
    div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
      h2(style: "margin: 0;") { "No batches yet" }
      p(style: "color: var(--foreground2);") { "Upload a CSV to create your first batch." }
      a(href: new_batch_path) { "+ Upload CSV" }
    end
  end
end
