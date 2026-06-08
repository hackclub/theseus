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
    header_section
    stats_section
    filters_section
    letters_list
    pagination_section
  end

  private

  attr_reader :letters, :all_letters, :search, :status, :origin, :user_id, :users

  def header_section
    row("align-": "start between", style: "margin-bottom: 1lh;") do
      row("gap-": "1", "align-": "center") do
        h1(style: "margin: 0;") { "Letters" }
        render Components::Shared::Jumpcode.new(path: letters_path)
      end
      a(href: new_letter_path) do
        button("size-": "small", "variant-": "green") { "+ Send Letter" }
      end
    end
    p(style: "color: var(--foreground2); margin: 0 0 1lh;") do
      plain "#{letters.respond_to?(:total_count) ? letters.total_count : letters.count} letters"
    end
  end

  def stats_section
    counts = {
      pending: all_letters.where(aasm_state: :pending).count,
      printed: all_letters.where(aasm_state: :printed).count,
      mailed: all_letters.where(aasm_state: :mailed).count,
      received: all_letters.where(aasm_state: :received).count
    }

    row("gap-": "1", style: "margin-bottom: 1lh; flex-wrap: wrap;") do
      stat_pill("Pending", counts[:pending], "yellow", "pending")
      stat_pill("Printed", counts[:printed], "background2", "printed")
      stat_pill("Mailed", counts[:mailed], "blue", "mailed")
      stat_pill("Received", counts[:received], "green", "received")
    end
  end

  def stat_pill(label, count, variant, filter_status)
    is_active = status == filter_status
    href = is_active ? letters_path(origin: origin, search: search, user_id: user_id) : letters_path(origin: origin, search: search, user_id: user_id, status: filter_status)
    a(href: href, style: "text-decoration: none;") do
      span("is-": "badge", "variant-": is_active ? variant : "background2") do
        strong { count.to_s }
        plain " #{label}"
      end
    end
  end

  def filters_section
    row("gap-": "1", "align-": "center", style: "margin-bottom: 1lh; flex-wrap: wrap;") do
      form_tag(letters_path, method: :get) do
        hidden_field_tag(:status, status) if status.present?
        hidden_field_tag(:origin, origin) if origin.present?
        hidden_field_tag(:user_id, user_id) if user_id.present?
        input(type: "text", name: "search", placeholder: "Search...", value: search, style: "width: 28ch;")
      end

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { letters_path(search: search, status: status, origin: origin, user_id: uid) }
        )
      end

      origin_filter_section

      if search.present? || status.present? || origin.present? || user_id.present?
        a(href: letters_path, style: "color: var(--foreground2);") { "× Clear" }
      end
    end
  end

  def origin_filter_section
    origins = [
      { key: nil, label: "All" },
      { key: "manual", label: "Manual" },
      { key: "bulk_upload", label: "Bulk" },
      { key: "queue", label: "Queue" },
      { key: "api", label: "API" },
    ]
    origins.each do |o|
      is_active = origin == o[:key]
      a(
        href: letters_path(origin: o[:key], search: search, status: status, user_id: user_id),
        style: "text-decoration: none; #{'font-weight: bold; color: var(--foreground0);' if is_active}"
      ) do
        span("is-": "badge", "variant-": is_active ? "foreground0" : "background2") { o[:label] }
      end
    end
  end

  def letters_list
    if letters.any?
      table do
        thead do
          tr do
            th { "Letter" }
            th { "Recipient" }
            th { "Batch" }
            th { "Status" }
          end
        end
        tbody do
          letters.each { |l| render_letter_row(l) }
        end
      end
    else
      div("box-": "round", style: "text-align: center; padding: 2lh 2ch;") do
        p(style: "margin: 0;") { "No letters found." }
        if !(search.present? || status.present?)
          a(href: new_letter_path) { button("size-": "small", "variant-": "green") { "Send Letter" } }
        end
      end
    end
  end

  def render_letter_row(letter)
    tr do
      td do
        a(href: letter_path(letter), style: "text-decoration: none; color: var(--foreground0);") do
          strong { letter.public_id }
        end
        render_tags(letter.tags.first(2)) if letter.tags.present?
        div(style: "color: var(--foreground2); font-size: 0.85em;") do
          plain letter.created_at.strftime("%b %d, %Y")
          plain " · #{letter.origin_label}"
          if letter.mailed_at
            plain " · Mailed #{time_ago_in_words(letter.mailed_at)} ago"
          end
        end
      end
      td do
        plain letter.address&.name_line || "—"
        if letter.recipient_email.present?
          div(style: "color: var(--foreground2); font-size: 0.85em;") { letter.recipient_email }
        end
      end
      td do
        if letter.batch_id.present?
          span("is-": "badge", "variant-": "background2") { "##{letter.batch_id}" }
        else
          span(style: "color: var(--foreground2);") { "—" }
        end
      end
      td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
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
