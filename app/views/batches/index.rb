# frozen_string_literal: true

class Views::Batches::Index < Views::Base
  def initialize(batches:)
    @batches = batches
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(title: "Batches", subtitle: "#{@batches.count} batches") do |header|
        header.with_actions do
          render Primer::Beta::Button.new(tag: :a, href: new_batch_path, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :plus)
            "Upload CSV"
          end
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
    render Primer::Beta::BorderBox.new(padding: :condensed) do |box|
      @batches.each do |batch|
        box.with_row do
          batch_row(batch)
        end
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
        render Primer::Beta::Button.new(tag: :a, href: batch_path(batch), scheme: :secondary, size: :small) do |btn|
          btn.with_trailing_visual_icon(icon: :arrow_right)
          "View Details"
        end
      end
    end
  end

  def blankslate
    render Primer::Beta::Blankslate.new(border: true) do |bs|
      bs.with_visual_icon(icon: :inbox)
      bs.with_heading(tag: :h2) { "No batches yet" }
      bs.with_description { "Get started by uploading a CSV file." }
      bs.with_primary_action(href: new_batch_path) do
        render Primer::Beta::Button.new(scheme: :primary) do |btn|
          btn.with_leading_visual_icon(icon: :plus)
          "Upload CSV"
        end
      end
    end
  end
end
