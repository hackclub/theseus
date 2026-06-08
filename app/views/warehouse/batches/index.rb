# frozen_string_literal: true

class Views::Warehouse::Batches::Index < Views::Base
  def initialize(batches:)
    @batches = batches
  end

  def view_template
    toolbar
    stat_filters
    batches_table
  end

  private

  def toolbar
    render Components::Shared::PageToolbar.new(
      title: "Warehouse Batches",
      jumpcode_path: warehouse_batches_path,
      action_href: new_warehouse_batch_path,
      action_label: "+ New Batch"
    )
  end

  def stat_filters
    counts = {
      awaiting_field_mapping: @batches.where(aasm_state: :awaiting_field_mapping).count,
      fields_mapped: @batches.where(aasm_state: :fields_mapped).count,
      processed: @batches.where(aasm_state: :processed).count
    }

    render Components::Shared::StatFilters.new(
      stats: [
        { label: "Awaiting Mapping", count: counts[:awaiting_field_mapping], color: "yellow", param: "awaiting_field_mapping" },
        { label: "Fields Mapped", count: counts[:fields_mapped], color: "blue", param: "fields_mapped" },
        { label: "Processed", count: counts[:processed], color: "green", param: "processed" },
      ],
      active: nil,
      base_path: ->(**_params) { warehouse_batches_path },
      total: @batches.count
    )
  end

  def batches_table
    if @batches.any?
      table do
        thead do
          tr do
            th { "ID" }
            th { "Date" }
            th { "Template" }
            th { "Addresses" }
            th { "Orders" }
            th { "Status" }
          end
        end
        tbody do
          @batches.each { |batch| render_batch_row(batch) }
        end
      end
    else
      blankslate
    end
  end

  def render_batch_row(batch)
    tr do
      td do
        a(href: warehouse_batch_path(batch), style: "text-decoration: none; color: var(--foreground0);") do
          plain "##{batch.id}"
        end
        if batch.tags.any?
          plain " "
          batch.tags.first(2).compact_blank.each do |t|
            span(style: "color: var(--foreground2); font-size: 0.8em;") { t }
            plain " "
          end
        end
      end
      td(style: "color: var(--foreground2);") { plain batch.created_at.strftime("%b %d") }
      td { plain batch.warehouse_template&.name || "—" }
      td(style: "color: var(--foreground2);") { plain batch.address_count&.to_s || "0" }
      td(style: "color: var(--foreground2);") { plain batch.orders.size.to_s }
      td { render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch) }
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