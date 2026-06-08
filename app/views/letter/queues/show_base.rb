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
    div(class: "page-container") do
      header_section
      stats_row
      make_batch_section
      letters_section
      batches_section
      queue_details_section
      admin_inspector(queue)
    end
  end

  private

  attr_reader :queue, :letters, :batches, :letter_counts, :search, :status

  # --- Header ---

  def header_section
    div(class: "page-header") do
      div do
        h1(class: "page-title") { queue.name }
        p(class: "page-subtitle") do
          plain "#{type_label} · #{queue.slug}"
        end
      end

      div(class: "page-actions") do
        a(href: letter_queues_path, style: "color: var(--foreground2);") { "← Back to queues" }
        a(href: edit_queue_path) do
          button("size-": "small") { "✎ Edit" }
        end
        admin_tool do
          form_with(url: queue_show_path, method: :delete, class: "form-inline") do
            button(type: "submit", "variant-": "red", "size-": "small") { "✕ Delete" }
          end
        end
      end
    end
  end

  # --- Stats Row ---

  def stats_row
    active_states = LETTER_STATES.select { |s| letter_counts.fetch(s, 0) > 0 }
    return if active_states.empty?

    div(class: "filter-bar content-section") do
      active_states.each do |state|
        span("is-": "badge", "variant-": state_badge_variant(state)) do
          "#{letter_counts[state]} #{state}"
        end
      end
    end
  end

  # Hook for subclasses (e.g. make batch button + dialog)
  def make_batch_section; end

  # --- Letters Section ---

  def letters_section
    collapsible_section("Letters", letters.count, open: true) do
      letters_filter_bar
      if letters.any?
        div("box-": "round") do
          letters.each do |letter|
            letter_row(letter)
            div("is-": "separator")
          end
        end
      else
        div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
          h3(style: "margin: 0;") { "No letters" }
          if search.present? || status.present?
            p(style: "color: var(--foreground2);") { "Try adjusting your search or filters." }
          end
        end
      end
    end
  end

  def letters_filter_bar
    div(class: "filter-bar mb-3") do
      # Search
      div(class: "flex-1") do
        form(action: queue_show_path, method: "get", class: "form-inline") do
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

      # Status toggles
      div(class: "page-actions") do
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
            a(href: href) do
              button("size-": "small", "variant-": "green") { "#{count} #{state}" }
            end
          else
            a(href: href, style: "color: var(--foreground2);") { "#{count} #{state}" }
          end
        end
      end

      # Clear filters
      if search.present? || status.present?
        a(href: queue_show_path, style: "color: var(--foreground2);") { "× Clear" }
      end
    end
  end

  # --- Batches Section (no-op by default) ---

  def batches_section; end

  # --- Queue Details ---

  def queue_details_section
    collapsible_section("Queue Details") do
      div("box-": "round") do
        admin_tool do
          div(style: "padding: 1lh 1ch;") do
            strong { "Owner" }
            div(class: "detail-value") do
              render_user_mention(queue.user)
            end
          end
          div("is-": "separator")
        end

        if queue.tags.any?
          div(style: "padding: 1lh 1ch;") do
            strong { "Tags" }
            div(class: "detail-value tags-inline") do
              queue.tags.each do |t|
                span("is-": "badge") { t }
              end
            end
          end
          div("is-": "separator")
        end

        div(style: "padding: 1lh 1ch;") do
          strong { "Return Address" }
          div(class: "detail-value") do
            if queue.letter_return_address.present?
              render_address(queue)
            else
              span(class: "kv-label") { "No return address" }
            end
          end
        end
        div("is-": "separator")

        div(style: "padding: 1lh 1ch;") do
          strong { "Mailer ID" }
          div(class: "detail-value") do
            plain(queue.letter_mailer_id&.display_name || "No mailer ID")
          end
        end
        div("is-": "separator")

        div(style: "padding: 1lh 1ch;") do
          strong { "Letter Specs" }
          div(class: "detail-value") do
            span { "#{queue.letter_width}\" × #{queue.letter_height}\" · #{queue.letter_weight} oz" }
          end
        end

        extra_queue_details
      end
    end
  end

  # Hook for subclasses to add extra detail rows
  def extra_queue_details; end

  # --- Helpers ---

  def letter_row(letter)
    div(class: "queue-letter-row") do
      a(href: letter_path(letter), class: "queue-letter-id") { letter.public_id }
      span(class: "flex-1") do
        name = [letter.address&.first_name, letter.address&.last_name].compact_blank.join(" ")
        plain name.presence || "—"
      end
      render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter)
      span(class: "index-card-meta") do
        letter.created_at.strftime("%b %d, %Y")
      end
    end
  end

  def render_address(q)
    addr = q.letter_return_address
    name = q.letter_return_address_name.presence || addr.name

    div do
      div { name } if name.present?
      div { addr.line_1 }
      div { addr.line_2 } if addr.line_2.present?
      div { "#{addr.city}, #{addr.state} #{addr.postal_code}" }
      div { addr.country }
    end
  end

  def collapsible_section(title, count = nil, open: false)
    details(class: "collapsible-section-mt", **( open ? { open: true } : {})) do
      summary(class: "collapsible-summary collapsible-summary--flex") do
        label_text = count ? "#{title} (#{count})" : title
        h2(class: "section-heading-lg m-0") { label_text }
        span(class: "kv-label") { "▼" }
      end
      div(class: "collapsible-body collapsible-body--padded") do
        yield
      end
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

  def state_badge_variant(state)
    case state
    when "queued" then "blue"
    when "pending" then "yellow"
    when "printed" then "blue"
    when "mailed", "received" then "green"
    else nil
    end
  end

  def render_user_mention(user)
    div(class: "user-info #{current_user == user ? 'current-user' : ''}") do
      if user.icon_url.present?
        img(src: user.icon_url, width: 32, height: 32, class: "avatar", alt: "#{user.username}'s avatar")
      end
      span { user.username }
    end
  end

  def admin_inspector(record)
    admin_tool do
      details(class: "collapsible-section-mt") do
        summary { "Inspect \"#{record.class.name.underscore}\" record" }
        div(class: "inspector-border") do
          details(class: "inspector-inner") do
            summary { "View JSON" }
            div(class: "inspector-scroll") do
              pre(class: "inspector-pre") { JSON.pretty_generate(record.as_json) }
            end
          end
        end
      end
    end
  end

  # Abstract — subclasses must define these
  def type_label = raise(NotImplementedError)
  def edit_queue_path = raise(NotImplementedError)
  def queue_show_path(**) = raise(NotImplementedError)
end
