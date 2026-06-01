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
        render Primer::Beta::Button.new(tag: :a, href: letter_queues_path, scheme: :secondary, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back to queues"
        end
        render Primer::Beta::Button.new(tag: :a, href: edit_queue_path, scheme: :secondary, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :pencil)
          "Edit"
        end
        admin_tool do
          form_with(url: queue_show_path, method: :delete, class: "form-inline") do
            render Primer::Beta::Button.new(type: :submit, scheme: :danger, size: :small) do |btn|
              btn.with_leading_visual_icon(icon: :trash)
              "Delete"
            end
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
        render(Primer::Beta::Label.new(scheme: state_scheme(state), size: :large)) do
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
        render Primer::Beta::BorderBox.new do |box|
          letters.each do |letter|
            box.with_row do
              letter_row(letter)
            end
          end
        end
      else
        render Primer::Beta::Blankslate.new do |bs|
          bs.with_visual_icon(icon: :mail)
          bs.with_heading(tag: :h3) { "No letters" }
          if search.present? || status.present?
            bs.with_description { "Try adjusting your search or filters." }
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
          render Primer::Alpha::TextField.new(
            name: "search",
            label: "Search letters",
            visually_hide_label: true,
            placeholder: "Search by name or email...",
            value: search,
            leading_visual: { icon: :search },
            full_width: true
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

          render Primer::Beta::Button.new(
            tag: :a,
            href: href,
            scheme: is_active ? :primary : :invisible,
            size: :small
          ) do |btn|
            "#{count} #{state}"
          end
        end
      end

      # Clear filters
      if search.present? || status.present?
        render Primer::Beta::Button.new(
          tag: :a,
          href: queue_show_path,
          scheme: :invisible,
          size: :small
        ) do |btn|
          btn.with_leading_visual_icon(icon: :x)
          "Clear"
        end
      end
    end
  end

  # --- Batches Section (no-op by default) ---

  def batches_section; end

  # --- Queue Details ---

  def queue_details_section
    collapsible_section("Queue Details") do
      render Primer::Beta::BorderBox.new do |box|
        admin_tool do
          box.with_row do
            div do
              strong { "Owner" }
              div(class: "detail-value") do
                render_user_mention(queue.user)
              end
            end
          end
        end

        if queue.tags.any?
          box.with_row do
            div do
              strong { "Tags" }
              div(class: "detail-value tags-inline") do
                queue.tags.each do |tag|
                  render(Primer::Beta::Label.new(size: :medium)) { tag }
                end
              end
            end
          end
        end

        box.with_row do
          div do
            strong { "Return Address" }
            div(class: "detail-value") do
              if queue.letter_return_address.present?
                render_address(queue)
              else
                span(class: "kv-label") { "No return address" }
              end
            end
          end
        end

        box.with_row do
          div do
            strong { "Mailer ID" }
            div(class: "detail-value") do
              plain(queue.letter_mailer_id&.display_name || "No mailer ID")
            end
          end
        end

        box.with_row do
          div do
            strong { "Letter Specs" }
            div(class: "detail-value") do
              span { "#{queue.letter_width}\" × #{queue.letter_height}\" · #{queue.letter_weight} oz" }
            end
          end
        end

        extra_queue_details(box)
      end
    end
  end

  # Hook for subclasses to add extra detail rows
  def extra_queue_details(box); end

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
