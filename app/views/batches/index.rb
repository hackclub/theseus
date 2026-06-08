# frozen_string_literal: true

class Views::Batches::Index < Views::Base
  def initialize(batches:)
    @batches = batches
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Batches",
      action_href: new_batch_path,
      action_label: "+ Upload CSV"
    )

    if @batches.any?
      batches_table
    else
      div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
        strong { "No batches yet" }
        div(style: "margin-top: 0.5lh; color: var(--foreground2);") { "Upload a CSV to create your first batch." }
      end
    end
  end

  private

  def batches_table
    table(style: "width: 100%;") do
      thead do
        tr do
          th(style: "text-align: left;") { "Batch" }
          th(style: "text-align: left;") { "Type" }
          th(style: "text-align: left;") { "Created" }
          th(style: "text-align: right;") { "Addresses" }
          th(style: "text-align: left;") { "Status" }
        end
      end
      tbody do
        @batches.each { |batch| batch_row(batch) }
      end
    end
  end

  def batch_row(batch)
    tr do
      td(style: "padding: 0.25lh 1ch;") do
        a(href: batch_path(batch), style: "font-weight: bold; text-decoration: none;") { "##{batch.id}" }
        if batch.tags.any?
          batch.tags.each do |tag|
            span(class: "row-tag") { tag }
          end
        end
      end
      td(style: "padding: 0.25lh 1ch;") { batch.type.split("::").first.titleize }
      td(style: "padding: 0.25lh 1ch;") do
        plain batch.created_at.strftime(batch.created_at.year == Date.current.year ? "%b %d" : "%b %d, %Y")
      end
      td(style: "padding: 0.25lh 1ch; text-align: right; font-variant-numeric: tabular-nums;") { batch.addresses.count.to_s }
      td(style: "padding: 0.25lh 1ch;") do
        render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch)
      end
    end
  end
end
