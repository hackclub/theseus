# frozen_string_literal: true

class Views::Letters::Index < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  def initialize(letters:, all_letters:, search: nil, status: nil, origin: nil, user_id: nil, users: [])
    @letters = letters
    @all_letters = all_letters
    @search = search
    @status = status
    @origin = origin
    @user_id = user_id
    @users = users
  end

  def view_template
    div(class: "page-container") do
      header_section
      stats_section
      filters_section
      letters_list
      pagination_section
    end
  end

  private

  attr_reader :letters, :all_letters, :search, :status, :origin, :user_id, :users

  def header_section
    div(class: "page-header") do
      div do
        div(class: "page-title-group") do
          h1(class: "page-title") { "Letters" }
          render Components::Shared::Jumpcode.new(path: letters_path)
        end
        p(class: "page-subtitle mt-1") do
          plain "#{letters.respond_to?(:total_count) ? letters.total_count : letters.count} letters"
        end
      end

      a(href: new_letter_path) do
        button("variant-": "green") { "+ Send Letter" }
      end
    end
  end

  def stats_section
    counts = {
      pending: all_letters.where(aasm_state: :pending).count,
      printed: all_letters.where(aasm_state: :printed).count,
      mailed: all_letters.where(aasm_state: :mailed).count,
      received: all_letters.where(aasm_state: :received).count
    }

    div(class: "stat-pill-row") do
      stat_pill("Pending", counts[:pending], :attention, "pending")
      stat_pill("Printed", counts[:printed], :secondary, "printed")
      stat_pill("Mailed", counts[:mailed], :accent, "mailed")
      stat_pill("Received", counts[:received], :success, "received")
    end
  end

  def stat_pill(label, count, scheme, filter_status)
    is_active = status == filter_status
    href = if is_active
             letters_path(origin: origin, search: search, user_id: user_id)
           else
             letters_path(origin: origin, search: search, user_id: user_id, status: filter_status)
           end

    a(
      href: href,
      class: "stat-pill-link",
      data: { scheme: scheme, active: is_active ? "true" : nil }
    ) do
      span(class: "fw-semibold") { count.to_s }
      span(class: is_active ? "" : "kv-label") { label }
    end
  end

  def filters_section
    div(class: "filter-section") do
      div(class: "filter-search") do
        form_tag(letters_path, method: :get) do
          hidden_field_tag(:status, status) if status.present?
          hidden_field_tag(:origin, origin) if origin.present?
          hidden_field_tag(:user_id, user_id) if user_id.present?
          input(
            type: "text",
            name: "search",
            placeholder: "Search by recipient, title, or email...",
            value: search,
            style: "width: 100%;"
          )
        end
      end

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { letters_path(search: search, status: status, origin: origin, user_id: uid) }
        )
      end

      origin_filter_section

      has_filters = search.present? || status.present? || origin.present? || user_id.present?
      if has_filters
        a(href: letters_path, style: "color: var(--foreground2);") { "× Clear filters" }
      end
    end
  end

  def origin_filter_section
    origins = [
      { key: nil, label: "All", icon: "≡" },
      { key: "manual", label: "Manual", icon: "✎" },
      { key: "bulk_upload", label: "Bulk upload", icon: "↑" },
      { key: "queue", label: "Queue", icon: "☰" },
      { key: "api", label: "API", icon: "</>" },
    ]

    div(class: "filter-toggle-row") do
      origins.each do |o|
        is_active = origin == o[:key]
        a(
          href: letters_path(origin: o[:key], search: search, status: status, user_id: user_id),
          style: is_active ? "font-weight: bold;" : "color: var(--foreground2);"
        ) do
          button("size-": "small") { "#{o[:icon]} #{o[:label]}" }
        end
      end
    end
  end

  def letters_list
    if letters.any?
      div("box-": "round") do
        div(class: "letter-list-header", style: "padding: 0.5lh 1ch;") do
          span(class: "fw-semibold") { "Letter" }
          div(class: "letter-list-header-side") do
            span(class: "letter-list-col-recipient") { "Recipient" }
            span(class: "letter-list-col-batch") { "Batch" }
            span(class: "letter-list-col-status") { "Status" }
          end
        end
        letters.each do |letter|
          div("is-": "separator")
          render_letter_row(letter)
        end
      end
    else
      div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
        h2(style: "margin: 0;") { "No letters found" }
        if search.present? || status.present?
          p(style: "color: var(--foreground2);") { "Try adjusting your search or filters." }
        else
          p(style: "color: var(--foreground2);") { "Send your first letter to get started." }
          a(href: new_letter_path) { button("variant-": "green") { "Send Letter" } }
        end
      end
    end
  end

  def render_letter_row(letter)
    a(href: letter_path(letter), class: "letter-row") do
      div(class: "letter-row-main") do
        div(class: "letter-row-id-line") do
          span(class: "letter-row-id") do
            letter.public_id
          end
          if letter.user_facing_title.present?
            span { "·" }
            span(class: "letter-row-title") do
              letter.user_facing_title
            end
          end
          render_tags(letter.tags.first(2)) if letter.tags.present?
        end
        div(class: "letter-row-meta") do
          plain letter.created_at.strftime("%b %d, %Y")
          plain " · #{letter.origin_label}"
          if letter.mailed_at
            plain " · Mailed #{time_ago_in_words(letter.mailed_at)} ago"
          end
        end
      end

      div(class: "letter-row-side") do
        div(class: "letter-row-recipient") do
          div(class: "letter-row-recipient-name") { letter.address&.name_line || "—" }
          if letter.recipient_email.present?
            div(class: "letter-row-recipient-email") do
              letter.recipient_email
            end
          end
        end

        div(class: "letter-row-batch") do
          if letter.batch_id.present?
            span("is-": "badge") { "Batch ##{letter.batch_id}" }
          else
            span(class: "text-sm kv-label") { "—" }
          end
        end

        div(class: "letter-row-status") do
          render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter)
        end
      end
    end
  end

  def render_tags(tags)
    tags.compact_blank.each do |tag|
      span("is-": "badge") { tag }
    end
  end

  def pagination_section
    render Components::Shared::Pagination.new(
      collection: letters,
      base_path: method(:letters_path),
      filter_params: { search: search, status: status, origin: origin, user_id: user_id }
    )
  end

  def form_tag(url, method:, &block)
    form(action: url, method: method == :get ? "get" : "post", &block)
  end

  def hidden_field_tag(name, value)
    input(type: "hidden", name: name, value: value)
  end
end
