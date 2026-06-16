# frozen_string_literal: true

class Views::Letter::Queues::ShowBase < Views::Base
  include Phlex::Rails::Helpers::FormWith

  LETTER_STATES = %w[queued pending printed mailed received].freeze

  def initialize(queue:, letters:, batches:, letter_counts:, search: nil, status: nil)
    @queue = queue
    @letters = letters
    @batches = batches
    @letter_counts = letter_counts
    @search = search
    @status = status
  end

  def view_template
    header_section

    div(class: "show-layout") do
      div(class: "show-main") do
        queue_details_section
        letters_section
        batches_section
        admin_inspector(queue)
      end

      div(class: "show-sidebar") do
        actions_sidebar
        stats_sidebar
      end
    end
  end

  private

  attr_reader :queue, :letters, :batches, :letter_counts, :search, :status

  # --- Header ---

  def header_section
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: letter_queues_path, style: "text-decoration: none; color: GrayText;") { "← Queues" }
        strong(style: "font-size: 1.15em;") { queue.name }
        type_badge
        queue_status_badge
      end
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        span(class: "text-muted") { queue.slug }
      end
      span(class: "spacer")
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: edit_queue_path) { "✎ Edit" }
        admin_tool do
          form_with(url: queue_show_path, method: :delete, data: { turbo_confirm: "Delete this queue?" }, class: "form-inline") do
            button(type: "submit", class: "btn-danger btn-sm") { "✕" }
          end
        end
      end
    end
  end

  def type_badge
    raise NotImplementedError
  end

  def queue_status_badge
    total = LETTER_STATES.sum { |s| letter_counts.fetch(s, 0) }
    queued = letter_counts.fetch("queued", 0)
    if total == 0
      span(class: "badge") { "Empty" }
    elsif queued > 0
      span(class: "badge badge-info") { "#{queued} queued" }
    else
      span(class: "badge badge-success") { "Active" }
    end
  end

  # --- Queue Details ---

  def queue_details_section
    section(style: "margin-bottom: 1rem;") do
      strong { "Details" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        admin_tool do
          span(class: "detail-label") { "Owner" }
          span { render_user_mention(queue.user) }
        end

        span(class: "detail-label") { "Dimensions" }
        span { "#{queue.letter_width}\" × #{queue.letter_height}\" · #{queue.letter_weight} oz" }

        span(class: "detail-label") { "Mailer ID" }
        span { queue.letter_mailer_id&.display_name || "—" }

        if queue.tags.any?
          span(class: "detail-label") { "Tags" }
          span do
            queue.tags.each do |t|
              span(class: "badge") { t }
              plain " "
            end
          end
        end

        extra_queue_details
      end
    end

    return_address_box if queue.letter_return_address.present?
  end

  def return_address_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Return Address" }
      hr
      div(style: "margin-top: 0.5rem;") do
        render_address(queue)
      end
    end
  end

  # Hook for subclasses to add extra detail-grid rows
  def extra_queue_details; end

  # --- Letters Section ---

  def letters_section
    section(style: "margin-bottom: 1rem;") do
      div(style: "display:flex;align-items:center") do
        strong { "Letters" }
        span(class: "text-muted", style: "margin-left: 0.5rem;") { "(#{letters.count})" } if letters.any?
        span(style: "flex: 1;")
        if search.present? || status.present?
          a(href: queue_show_path, style: "color: GrayText; font-size: 0.9em;") { "× Clear filters" }
        end
      end
      hr

      letters_filter_bar

      if letters.any?
        table do
          thead do
            tr do
              th { "ID" }
              th { "Recipient" }
              th { "Status" }
              th { "Date" }
            end
          end
          tbody do
            letters.each { |letter| letter_row(letter) }
          end
        end
      else
        div(style: "text-align: center; padding: 2rem;", class: "text-muted") do
          if search.present? || status.present?
            plain "No letters match your filters."
          else
            plain "No letters yet."
          end
        end
      end
    end
  end

  def letters_filter_bar
    div(style: "display:flex;align-items:center;gap:0.5rem;padding:0.5rem 0;") do
      div(style: "flex: 1;") do
        form(action: queue_show_path, method: "get", style: "display: flex;") do
          input(type: "hidden", name: "status", value: status) if status.present?
          input(
            type: "text",
            name: "search",
            placeholder: "Search by name or email...",
            value: search,
            style: "width: 100%;"
          )
        end
      end

      LETTER_STATES.each do |state|
        count = letter_counts.fetch(state, 0)
        next if count == 0

        is_active = status == state
        href = if is_active
                 queue_show_path(search: search)
               else
                 queue_show_path(search: search, status: state)
               end

        if is_active
          a(href: href, style: "text-decoration: none;") do
            button(class: "#{state_badge_class(state)} btn-sm") { "#{count} #{state}" }
          end
        else
          a(href: href, style: "text-decoration: none; color: GrayText;") { "#{count} #{state}" }
        end
      end
    end
  end

  # --- Batches Section (no-op by default) ---

  def batches_section; end

  # Hook for subclasses (e.g. make batch button)
  def make_batch_section; end

  # --- Sidebar ---

  def actions_sidebar
    section(style: "margin-bottom: 1rem;") do
      strong { "Actions" }
      hr
      div(style: "margin-top: 0.5rem;") do
        make_batch_section
        a(href: edit_queue_path, style: "display: block; margin-top: 0.5rem;") do
          button(class: "btn-sm", style: "width: 100%;") { "✎ Edit Queue" }
        end
      end
    end
  end

  def stats_sidebar
    active_states = LETTER_STATES.select { |s| letter_counts.fetch(s, 0) > 0 }
    return if active_states.empty?

    section(style: "margin-bottom: 1rem;") do
      strong { "Stats" }
      hr
      div(style: "margin-top: 0.5rem;") do
        active_states.each do |state|
          div(style: "display:flex;align-items:center;justify-content:space-between;padding:0.25rem 0;") do
            span(class: "text-muted") { state.capitalize }
            span(class: "badge #{state_badge_class(state)}") { letter_counts[state].to_s }
          end
        end
        hr(style: "margin: 0.5rem 0;")
        div(style: "display:flex;align-items:center;justify-content:space-between;") do
          strong { "Total" }
          strong { LETTER_STATES.sum { |s| letter_counts.fetch(s, 0) }.to_s }
        end
      end
    end
  end

  # --- Helpers ---

  def letter_row(letter)
    tr do
      td do
        a(href: letter_path(letter), style: "text-decoration: none;") { letter.public_id }
      end
      td do
        name = [letter.address&.first_name, letter.address&.last_name].compact_blank.join(" ")
        plain name.presence || "—"
      end
      td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
      td(class: "text-muted", style: "text-align: right;") { letter.created_at.strftime("%b %-d") }
    end
  end

  def render_address(q)
    addr = q.letter_return_address
    name = q.letter_return_address_name.presence || addr.name

    div do
      strong { name } if name.present?
      div(class: "text-muted") do
        div { addr.line_1 }
        div { addr.line_2 } if addr.line_2.present?
        div { "#{addr.city}, #{addr.state} #{addr.postal_code}" }
        div { addr.country }
      end
    end
  end

  def state_badge_variant(state)
    case state
    when "queued" then "blue"
    when "pending" then "yellow"
    when "printed" then "blue"
    when "mailed", "received" then "green"
    end
  end

  def state_badge_class(state)
    case state
    when "queued" then "badge-info"
    when "pending" then "badge-warning"
    when "printed" then "badge-info"
    when "mailed", "received" then "badge-success"
    else ""
    end
  end

  def render_user_mention(user)
    div(style: "display:flex;align-items:center;gap:0.5rem") do
      if user.icon_url.present?
        img(src: user.icon_url, width: 20, height: 20, style: "border-radius: 50%;", alt: "")
      end
      span { user.username }
    end
  end

  def admin_inspector(record)
    admin_tool do
      details(style: "margin-top: 1rem;") do
        summary(style: "color: GrayText; cursor: pointer;") { "Inspect #{record.class.name.underscore}" }
        section(style: "margin-top: 0.5rem;") do
          pre(style: "margin: 0; overflow-x: auto; font-size: 0.85em;") { JSON.pretty_generate(record.as_json) }
        end
      end
    end
  end

  # Abstract — subclasses must define these
  def type_label = raise(NotImplementedError)
  def edit_queue_path = raise(NotImplementedError)
  def queue_show_path(**) = raise(NotImplementedError)
end
