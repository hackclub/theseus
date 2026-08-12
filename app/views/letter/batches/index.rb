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
      if @state.present? || @search.present?
        a(href: letter_batches_path, style: "color: var(--foreground2); white-space: nowrap;") { "× Clear" }
      end
    end
  end

  def stat_filters
    stats = [
      { param: nil, count: @batches.count, label: "All" },
      { param: "awaiting_field_mapping", count: @batches.where(aasm_state: "awaiting_field_mapping").count, label: "Awaiting", color: "yellow" },
      { param: "fields_mapped", count: @batches.where(aasm_state: "fields_mapped").count, label: "Mapped", color: "blue" },
      { param: "processed", count: @batches.where(aasm_state: "processed").count, label: "Processed", color: "green" },
      { param: "printed", count: @batches.where(aasm_state: "printed").count, label: "Printed" },
      { param: "mailed", count: @batches.where(aasm_state: "mailed").count, label: "Mailed" }
    ]

    render Components::Shared::StatFilters.new(
      stats: stats,
      active: @state,
      base_path: ->(status: nil, **) { letter_batches_path(state: status, search: @search) },
      filter_key: :status
    )
  end

  def batches_table
    filtered = if @state.present?
                 @batches.where(aasm_state: @state)
               else
                 @batches
               end

    table do
      thead do
        tr do
          th { "Batch" }
          th { "Origin" }
          th { "Letters" }
          th { "Created" }
          th { "Status" }
        end
      end
      tbody do
        filtered.order(created_at: :desc).limit(100).each do |batch|
          render_batch_row(batch)
        end
      end
    end
  end

  def render_batch_row(batch)
    tr do
      td do
        a(href: letter_batch_path(batch), style: "text-decoration: none; font-weight: 500;") do
          if batch.user_facing_title.present?
            plain batch.user_facing_title
          else
            plain "##{batch.id}"
          end
        end
        if batch.user_facing_title.present?
          span(class: "text-muted", style: "margin-left:0.5rem;font-size:0.85em;") { "##{batch.id}" }
        end
      end
      td(class: "text-muted") { batch.origin || "—" }
      td { format_number(batch.letters.size) }
      td(class: "text-muted") { batch.created_at.strftime("%b %-d, %Y") }
      td { render Components::Shared::StatusBadge.new(status: batch.aasm_state, type: :batch) }
    end
  end

  def format_number(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
