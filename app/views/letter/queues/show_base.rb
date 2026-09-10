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
        api_docs_section
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
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: letter_queues_path, class: "link-muted") { "← Queues" }
        strong(class: "text-title") { queue.name }
        type_badge
        queue_status_badge
      end
      div(class: "flex-row") do
        span(class: "text-muted") { queue.slug }
      end
      span(class: "spacer")
      div(class: "flex-row") do
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
    section(class: "mb-1") do
      strong { "Details" }
      hr
      div(class: "detail-grid mt-half") do
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
    section(class: "mb-1") do
      strong { "Return Address" }
      hr
      div(class: "mt-half") do
        render_address(queue)
      end
    end
  end

  # Hook for subclasses to add extra detail-grid rows
  def extra_queue_details; end

  # --- API docs ---

  def api_docs_section
    section(class: "mb-1") do
      details do
        summary(class: "text-muted pointer") { "API docs" }

        div(class: "mt-half") do
          p do
            plain "Send a POST request to "
            code(class: "pointer", data_copy_to_clipboard: api_endpoint_url) { api_endpoint_path }
            plain " with JSON like:"
          end

          example = JSON.pretty_generate(api_example_payload)
          pre(class: "json-inspector pointer", data_copy_to_clipboard: example) { example }
          small(class: "text-muted") { "(click that hunk of JSON to copy it)" }

          p do
            plain "Use an "
            code { "Authorization" }
            plain " header of "
            code { "Bearer <token>" }
            plain " with one of your "
            a(href: api_keys_path, target: "_blank") { "API keys" }
            plain "."
          end
        end
      end
    end
  end

  def api_example_payload
    {
      recipient_email: current_user.email,
      address: {
        first_name: "Bort",
        last_name: "Fargler",
        line_1: "8605 Santa Clausica Blvd.",
        line_2: "PMB 86294 (optional)",
        city: "West Sillywood",
        state: "CA",
        postal_code: "90069",
        country: "United States"
      },
      rubber_stamps: "extra text if the template you're using supports it",
      idempotency_key: "optional but it'd be a great idea... rec#{SecureRandom.alphanumeric 12}?",
      metadata: {
        whatever_you_want: "this gets JSONB'd, you can stash program-specific meta info here",
        seriously_any_keys_and_values: "as long as postgres can serialize it :3"
      }
    }
  end

  # --- Letters Section ---

  def letters_section
    section(class: "mb-1") do
      div(class: "row-flex") do
        strong { "Letters" }
        span(class: "text-muted ml-half") { "(#{letters.count})" } if letters.any?
        span(class: "flex-1")
        if search.present? || status.present?
          a(href: queue_show_path, class: "clear-filters-link") { "× Clear filters" }
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
        div(class: "empty-state text-muted") do
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
    div(class: "letters-filter-bar") do
      div(class: "flex-1") do
        form(action: queue_show_path, method: "get", class: "d-flex") do
          input(type: "hidden", name: "status", value: status) if status.present?
          input(
            type: "text",
            name: "search",
            placeholder: "Search by name or email...",
            value: search,
            class: "w-100"
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
          a(href: href, class: "no-underline") do
            button(class: "#{state_badge_class(state)} btn-sm") { "#{count} #{state}" }
          end
        else
          a(href: href, class: "link-muted") { "#{count} #{state}" }
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
    section(class: "mb-1") do
      strong { "Actions" }
      hr
      div(class: "mt-half") do
        make_batch_section
        a(href: edit_queue_path, class: "action-link-block") do
          button(class: "btn-sm w-100") { "✎ Edit Queue" }
        end
      end
    end
  end

  def stats_sidebar
    active_states = LETTER_STATES.select { |s| letter_counts.fetch(s, 0) > 0 }
    return if active_states.empty?

    section(class: "mb-1") do
      strong { "Stats" }
      hr
      div(class: "mt-half") do
        active_states.each do |state|
          div(class: "stat-row") do
            span(class: "text-muted") { state.capitalize }
            span(class: "badge #{state_badge_class(state)}") { letter_counts[state].to_s }
          end
        end
        hr(class: "mt-half mb-half")
        div(class: "stat-total-row") do
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
        a(href: letter_path(letter), class: "no-underline") { letter.public_id }
      end
      td do
        name = [ letter.address&.first_name, letter.address&.last_name ].compact_blank.join(" ")
        plain name.presence || "—"
      end
      td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
      td(class: "text-muted text-right") { letter.created_at.strftime("%b %-d") }
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
    div(class: "flex-row") do
      if user.icon_url.present?
        img(src: user.icon_url, width: 20, height: 20, class: "avatar-round", alt: "")
      end
      span { user.username }
    end
  end

  def admin_inspector(record)
    admin_tool do
      details(class: "mt-1") do
        summary(class: "text-muted pointer") { "Inspect #{record.class.name.underscore}" }
        section(class: "mt-half") do
          pre(class: "json-inspector") { JSON.pretty_generate(record.as_json) }
        end
      end
    end
  end

  # Abstract — subclasses must define these
  def type_label = raise(NotImplementedError)
  def edit_queue_path = raise(NotImplementedError)
  def queue_show_path(**) = raise(NotImplementedError)
  def api_endpoint_url = raise(NotImplementedError)
  def api_endpoint_path = raise(NotImplementedError)
end
