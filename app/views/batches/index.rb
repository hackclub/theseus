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
      section(class: "empty-state") do
        strong { "No batches yet" }
        div(class: "mt-half text-muted") { "Upload a CSV to create your first batch." }
      end
    end
  end

  private

  def batches_table
    table(class: "w-100") do
      thead do
        tr do
          th(class: "text-left") { "Batch" }
          th(class: "text-left") { "Type" }
          th(class: "text-left") { "Created" }
          th(class: "text-right") { "Addresses" }
          th(class: "text-left") { "Status" }
        end
      end
      tbody do
        @batches.each { |batch| batch_row(batch) }
      end
    end
  end

  def batch_row(batch)
    tr do
      td(class: "cell-pad") do
        a(href: batch_path(batch), class: "fw-bold no-underline") { "##{batch.id}" }
        if batch.tags.any?
          batch.tags.each do |tag|
            span(class: "row-tag") { tag }
          end
        end
      end
      td(class: "cell-pad") { batch.type.split("::").first.titleize }
      td(class: "cell-pad") do
        plain batch.created_at.strftime(batch.created_at.year == Date.current.year ? "%b %d" : "%b %d, %Y")
      end
      td(class: "num-cell") { batch.addresses.count.to_s }
      td(class: "cell-pad") do
        render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch)
      end
    end
  end
end
