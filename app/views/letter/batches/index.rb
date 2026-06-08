# frozen_string_literal: true

class Views::Letter::Batches::Index < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  def initialize(batches:, search: nil, state: nil)
    @batches = batches
    @search = search
    @state = state
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(
        title: "Letter Batches",
        subtitle: "#{@batches.count} batches",
        jumpcode_path: letter_batches_path
      ) do |header|
        header.with_actions do
          a(href: new_letter_batch_path) do
            button("variant-": "green") { "+ New Batch" }
          end
      end

      filters_section

      if @batches.any?
        batches_list
      else
        blankslate
      end
    end
  end

  private

  def filters_section
    div(class: "filter-bar-wrap") do
      div(class: "filter-search") do
        form(action: letter_batches_path, method: "get", class: "form-contents") do
          input(type: "hidden", name: "state", value: @state) if @state.present?
          input(
            type: "text",
            name: "search",
            placeholder: "Search by tag, user...",
            value: @search,
            style: "width: 100%;"
          )
        end
      end

      div(class: "filter-toggle-row") do
        state_pill("Open", "awaiting_field_mapping")
        state_pill("Mapped", "fields_mapped")
        state_pill("Processed", "processed")
      end

      if @search.present? || @state.present?
        a(href: letter_batches_path, style: "color: var(--foreground2);") { "× Clear" }
      end
    end
  end

  def state_pill(label, filter_state)
    is_active = @state == filter_state
    href = if is_active
             letter_batches_path(search: @search)
           else
             letter_batches_path(search: @search, state: filter_state)
           end

    if is_active
      a(href: href) { button("variant-": "green", "size-": "small") { label } }
    else
      a(href: href) { button("size-": "small") { label } }
    end
  end

  def batches_list
    div("box-": "round") do
      @batches.each do |batch|
        div(style: "padding: 1lh 1ch;") do
          batch_row(batch)
        end
        div("is-": "separator")
      end
    end
  end

  def batch_row(batch)
    div(class: "batch-index-row") do
      div(class: "batch-index-row-main") do
        div(class: "batch-index-row-title") do
          h3(class: "section-heading-lg m-0") do
            a(href: letter_batch_path(batch), class: "link-reset") do
              "Letter Batch ##{batch.id}"
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
            strong { "Addresses: " }
            plain batch.addresses.count.to_s
          end
          span do
            strong { "Letters: " }
            plain batch.letters.count.to_s
          end
          span do
            plain time_ago_in_words(batch.created_at)
            plain " ago"
          end
        end
      end

      div(class: "flex-shrink-0") do
        a(href: letter_batch_path(batch)) { button("size-": "small") { "View →" } }
    end
  end

  def blankslate
    div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
      h2(style: "margin: 0;") { "No letter batches yet" }
      p(style: "color: var(--foreground2);") { "Create a batch to send letters to multiple addresses at once." }
      a(href: new_letter_batch_path) { button("variant-": "green") { "+ New Batch" } }
    end
  end
end
