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
          a(href: new_warehouse_batch_path, "variant-": "green") { "+ New Batch" }
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
    div("box-": "round") do
      @batches.each do |batch|
        batch_row(batch)
        div("is-": "separator") unless batch == @batches.last
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
        a(href: warehouse_batch_path(batch), "size-": "small") { "View →" }
      end
    end
  end

  def blankslate
    div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
      h2(style: "margin: 0;") { "📦 No warehouse batches yet" }
      p(style: "color: var(--foreground2);") { "Create a batch to ship items to multiple addresses at once." }
      a(href: new_warehouse_batch_path, "variant-": "green") { "+ New Batch" }
    end
  end
end
