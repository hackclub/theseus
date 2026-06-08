# frozen_string_literal: true

class Views::Batches::Index < Views::Base
  def initialize(batches:)
    @batches = batches
  end

  def view_template
    div(class: "page-toolbar") do
      row("gap-": "1", "align-": "center") do
        strong(style: "font-size: 1.15em;") { "Batches" }
        span(style: "color: var(--foreground2);") { "#{@batches.count} batches" }
      end
      div(class: "toolbar-spacer")
      a(href: new_batch_path, "size-": "small") { "+ Upload CSV" }
    end

    if @batches.any?
      batches_grid
    else
      blankslate
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
    row("gap-": "2", "align-": "center") do
      div(style: "flex: 1; min-width: 0;") do
        row("gap-": "1", "align-": "center") do
          strong { "#{batch.type.split('::').first.titleize} Batch ##{batch.id}" }
          render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch)
        end

        if batch.tags.any?
          div(style: "margin-top: 0.25lh;") do
            render Components::Shared::Tags.new(tags: batch.tags)
          end
        end

        div(style: "color: var(--foreground2);") do
          span { "#{batch.type.split('::').first.titleize}" }
          plain " · "
          span { "#{time_ago_in_words(batch.created_at)} ago" }
          plain " · "
          span { "#{batch.addresses.count} addresses" }
        end
      end

      a(href: batch_path(batch), "size-": "small") { "View →" }
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
