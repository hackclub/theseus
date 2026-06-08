# frozen_string_literal: true

class Views::Letter::Batches::Index < Views::Base
  def initialize(batches:, search: nil, state: nil)
    @batches = batches
    @search = search
    @state = state
  end

  def view_template
    toolbar
    stat_filters
    batches_table
  end

  private

  def toolbar
    render Components::Shared::PageToolbar.new(
      title: "Letter Batches",
      jumpcode_path: letter_batches_path,
      search_path: letter_batches_path,
      search_value: @search,
      search_placeholder: "Search batches...",
      search_params: { state: @state },
      action_href: new_letter_batch_path,
      action_label: "+ New Batch"
    ) do
      if @search.present? || @state.present?
        a(href: letter_batches_path, class: "stat-filter") { "× Clear" }
      end
    end
  end

  def stat_filters
    counts = {
      awaiting_field_mapping: @batches.select { |b| b.aasm_state == "awaiting_field_mapping" }.size,
      fields_mapped: @batches.select { |b| b.aasm_state == "fields_mapped" }.size,
      processed: @batches.select { |b| b.aasm_state == "processed" }.size
    }

    render Components::Shared::StatFilters.new(
      stats: [
        { label: "Open", count: counts[:awaiting_field_mapping], color: "yellow", param: "awaiting_field_mapping" },
        { label: "Mapped", count: counts[:fields_mapped], color: "blue", param: "fields_mapped" },
        { label: "Processed", count: counts[:processed], color: "green", param: "processed" }
      ],
      active: @state,
      filter_key: :state,
      base_path: ->(params = {}) { letter_batches_path(search: @search, **params) },
      preserved_params: { search: @search },
      total: @batches.size
    )
  end

  def batches_table
    filtered = if @state.present?
                 @batches.select { |b| b.aasm_state == @state }
               else
                 @batches
               end

    if filtered.any?
      table do
        thead do
          tr do
            th { "Batch" }
            th { "Date" }
            th { "Letters" }
            th { "Addresses" }
            th { "Status" }
          end
        end
        tbody do
          filtered.each { |batch| render_batch_row(batch) }
        end
      end
    else
      div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
        h2(style: "margin: 0;") { "No letter batches yet" }
        p(style: "color: var(--foreground2);") { "Create a batch to send letters to multiple addresses at once." }
        a(href: new_letter_batch_path) { button("variant-": "green") { "+ New Batch" } }
      end
    end
  end

  def render_batch_row(batch)
    tr do
      td do
        a(href: letter_batch_path(batch), style: "text-decoration: none; color: var(--foreground0);") do
          plain batch.public_id
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
      td { plain format_number(batch.letters.size) }
      td { plain format_number(batch.addresses.size) }
      td { render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch) }
    end
  end

  def format_number(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
