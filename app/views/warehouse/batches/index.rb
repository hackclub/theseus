# frozen_string_literal: true

class Views::Warehouse::Batches::Index < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  def initialize(batches:)
    @batches = batches
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(
        title: "Warehouse Batches",
        subtitle: "#{@batches.count} batches",
        jumpcode_path: warehouse_batches_path
      ) do |header|
        header.with_actions do
          render Primer::Beta::Button.new(tag: :a, href: new_warehouse_batch_path, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :plus)
            "New Batch"
          end
        end
      end

      if @batches.any?
        batches_list
      else
        blankslate
      end
    end
  end

  private

  def batches_list
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
      div(class: "batch-index-row-main") do
        div(class: "batch-index-row-title") do
          h3(class: "section-heading-lg") do
            a(href: warehouse_batch_path(batch), class: "link-reset") do
              "Warehouse Batch ##{batch.id}"
            end
          end
          render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch)
        end

        if batch.tags.any?
          div(class: "mb-2") do
            render Components::Shared::Tags.new(tags: batch.tags)
          end
        end

        div(class: "index-card-meta") do
          span do
            strong { "Template: " }
            plain batch.warehouse_template&.name || "—"
          end
          span do
            strong { "Addresses: " }
            plain batch.addresses.count.to_s
          end
          span do
            plain time_ago_in_words(batch.created_at)
            plain " ago"
          end
        end
      end

      div(class: "batch-index-row-actions") do
        render Primer::Beta::Button.new(tag: :a, href: warehouse_batch_path(batch), scheme: :secondary, size: :small) do |btn|
          btn.with_trailing_visual_icon(icon: :"arrow-right")
          "View"
        end
      end
    end
  end

  def blankslate
    render Primer::Beta::Blankslate.new(border: true) do |bs|
      bs.with_visual_icon(icon: :package)
      bs.with_heading(tag: :h2) { "No warehouse batches yet" }
      bs.with_description { "Create a batch to ship items to multiple addresses at once." }
      bs.with_primary_action(href: new_warehouse_batch_path) do
        render Primer::Beta::Button.new(scheme: :primary) do |btn|
          btn.with_leading_visual_icon(icon: :plus)
          "New Batch"
        end
      end
    end
  end
end
