# frozen_string_literal: true

class Views::Letter::Queues::Index < Views::Base
  def initialize(letter_queues:, all_queues:, letter_counts:, user_id: nil, queue_type: nil, users: [])
    @letter_queues = letter_queues
    @all_queues = all_queues
    @letter_counts = letter_counts
    @user_id = user_id
    @queue_type = queue_type
    @users = users
  end

  def view_template
    div(class: "page-container") do
      header_section
      filters_section
      queue_grid_section
    end
  end

  private

  attr_reader :letter_queues, :all_queues, :letter_counts, :user_id, :queue_type, :users

  def header_section
    div(class: "page-header") do
      div do
        div(class: "page-title-group") do
          h1(class: "page-title") { "Queues" }
          render Components::Shared::Jumpcode.new(path: letter_queues_path)
        end
        p(class: "page-subtitle mt-1") do
          plain "#{letter_queues.count} #{"queue".pluralize(letter_queues.count)}"
        end
      end

      div(class: "page-actions") do
        admin_tool do
          button_to mark_printed_instants_mailed_letter_queues_path, method: :post, class: "btn-danger-sm" do
            "Mark printed instants mailed"
          end
        end

        div(class: "dropdown-container", style: "position: relative;") do
          row( "gap-": "1") do
            a(href: new_letter_queue_path) do
              button("size-": "small") { "⊞ Batch queue" }
            end
            a(href: new_letter_instant_queue_path) do
              button("size-": "small") { "↯ Instant queue" }
            end
          end
        end
      end
    end
  end

  def filters_section
    div(class: "filter-section") do
      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { letter_queues_path(user_id: uid, queue_type: queue_type) }
        )
      end

      type_toggle

      if user_id.present? || queue_type.present?
        a(href: letter_queues_path, style: "color: var(--foreground2);") { "× Clear filters" }
      end
    end
  end

  def type_toggle
    types = [
      { key: nil, label: "All", icon: :rows },
      { key: "batch", label: "Batch", icon: :stack },
      { key: "instant", label: "Instant", icon: :zap },
    ]

    div(class: "filter-toggle-row") do
      types.each do |t|
        is_active = queue_type == t[:key]
          if is_active
            a(href: letter_queues_path(queue_type: t[:key], user_id: user_id)) do
              button("size-": "small", "variant-": "green") { t[:label] }
            end
          else
            a(href: letter_queues_path(queue_type: t[:key], user_id: user_id), style: "color: var(--foreground2);") do
              plain t[:label]
            end
          end
      end
    end
  end

  def queue_grid_section
    if letter_queues.any?
      div(class: "queue-card-grid") do
        sorted_queues.each { |q| queue_card(q) }
      end
    else
      blankslate
    end
  end

  def sorted_queues
    letter_queues.sort_by do |q|
      if q.is_a?(::Letter::InstantQueue)
        printed = count_for(q, "printed")
        printed > 0 ? [1, -printed] : [2, q.name.downcase]
      else
        queued = count_for(q, "queued")
        queued > 0 ? [0, -queued] : [2, q.name.downcase]
      end
    end
  end

  def queue_card(queue)
    is_instant = queue.is_a?(::Letter::InstantQueue)
    href = is_instant ? letter_instant_queue_path(queue, status: :printed) : letter_queue_path(queue, status: :queued)
    action = attention_count(queue)

    if action > 0
      bg = is_instant ? "var(--bgColor-done-muted)" : "var(--bgColor-accent-muted)"
      border = is_instant ? "var(--borderColor-done-emphasis)" : "var(--borderColor-accent-emphasis)"
      box_style = "background: #{bg}; border-color: #{border};"
    else
      box_style = nil
    end

    a(href: href, class: "link-reset d-block") do
      div("box-": "round", style: box_style) do
        div(class: "queue-card-header", style: "padding: 1lh 1ch;") do
          span(class: "queue-card-name") do
            queue.name
          end
          if is_instant
            span("is-": "badge", "variant-": "green") { "Instant" }
          else
            span("is-": "badge", "variant-": "blue") { "Batch" }
          end
        end
        div("is-": "separator")
        div(class: "queue-card-stat", style: "padding: 1lh 1ch;") do
          if action > 0
            label = is_instant ? "awaiting mail" : "queued"
            span(class: "stat-value") { action.to_s }
            span(class: "page-subtitle") { label }
          else
            span(class: "stat-value kv-label") { "—" }
            span(class: "page-subtitle") { "idle" }
          end
        end
      end
    end
  end

  def blankslate
    div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
      h2(style: "margin: 0;") { "No queues found" }
      if queue_type.present? || user_id.present?
        p(style: "color: var(--foreground2);") { "Try adjusting your filters." }
      else
        p(style: "color: var(--foreground2);") { "Create a queue to get started." }
        a(href: new_letter_queue_path) { button("size-": "small", "variant-": "green") { "New Queue" } }
      end
    end
  end

  def count_for(queue, state)
    letter_counts[[queue.id, state]] || 0
  end

  def attention_count(queue)
    count_for queue, case queue
                     when ::Letter::InstantQueue
                       "printed"
                     else
                       "queued"
    end
  end

  def state_scheme(state)
    case state
    when "queued" then :secondary
    when "pending" then :attention
    when "printed" then :accent
    when "mailed", "received" then :success
    else :secondary
    end
  end
end
