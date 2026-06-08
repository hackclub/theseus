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
    toolbar
    letters_list
    pagination_section
  end

  private

  attr_reader :letters, :all_letters, :search, :status, :origin, :user_id, :users

  def toolbar
    # Row 1: Title + search + filters + action
    row("gap-": "2", "align-": "center", style: "flex-wrap: wrap; margin-bottom: 0.5lh;") do
      row("gap-": "1", "align-": "center", style: "flex-shrink: 0;") do
        strong(style: "font-size: 1.2em;") { "Letters" }
        render Components::Shared::Jumpcode.new(path: letters_path)
      end

      form_tag(letters_path, method: :get) do
        hidden_field_tag(:status, status) if status.present?
        hidden_field_tag(:origin, origin) if origin.present?
        hidden_field_tag(:user_id, user_id) if user_id.present?
        input(type: "text", name: "search", placeholder: "Search...", value: search, style: "width: 20ch;")
      end

      row("gap-": "1", "align-": "center") do
        origin_filters
      end

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { letters_path(search: search, status: status, origin: origin, user_id: uid) }
        )
      end

      if search.present? || status.present? || origin.present? || user_id.present?
        a(href: letters_path, style: "text-decoration: none; color: var(--foreground2);") { "× Clear" }
      end

      span(style: "flex: 1;")
      a(href: new_letter_path) { button("variant-": "green") { "+ Send Letter" } }
    end

    # Row 2: Status counts as filter links
    counts = {
      pending: all_letters.where(aasm_state: :pending).count,
      printed: all_letters.where(aasm_state: :printed).count,
      mailed: all_letters.where(aasm_state: :mailed).count,
      received: all_letters.where(aasm_state: :received).count
    }
    row("gap-": "2", "align-": "center", style: "color: var(--foreground2); margin-bottom: 0.5lh;") do
      stat_link("Pending", counts[:pending], "yellow", "pending")
      stat_link("Printed", counts[:printed], nil, "printed")
      stat_link("Mailed", counts[:mailed], "blue", "mailed")
      stat_link("Received", counts[:received], "green", "received")
      span(style: "color: var(--foreground2);") do
        total = letters.respond_to?(:total_count) ? letters.total_count : letters.count
        plain "#{total} total"
      end
    end
  end

  def stat_link(label, count, color_name, filter_status)
    is_active = status == filter_status
    href = is_active ? letters_path(origin: origin, search: search, user_id: user_id) : letters_path(origin: origin, search: search, user_id: user_id, status: filter_status)
    color = color_name ? "var(--#{color_name})" : "var(--foreground1)"
    a(href: href, style: "text-decoration: none; color: #{is_active ? color : 'var(--foreground2)'}; #{'font-weight: bold;' if is_active}") do
      plain "#{label} "
      span(style: "color: #{color};") { count.to_s }
    end
  end

  def origin_filters
    [nil, "manual", "bulk_upload", "queue", "api"].each do |key|
      lbl = { nil => "All", "manual" => "Manual", "bulk_upload" => "Bulk", "queue" => "Queue", "api" => "API" }[key]
      is_active = origin == key
      a(
        href: letters_path(origin: key, search: search, status: status, user_id: user_id),
        style: "text-decoration: none; color: var(--foreground#{is_active ? '0' : '2'}); #{'font-weight: bold;' if is_active}"
      ) { lbl }
    end
  end

  def letters_list
    if letters.any?
      table do
        thead do
          tr do
            th { "ID" }
            th { "Date" }
            th { "Recipient" }
            th { "Origin" }
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
          a(href: new_letter_path) { button("variant-": "green") { "Send Letter" } }
        end
      end
    end
  end

  def render_letter_row(letter)
    tr do
      td do
        a(href: letter_path(letter), style: "text-decoration: none; color: var(--foreground0);") do
          plain letter.public_id
        end
        if letter.tags.present?
          plain " "
          letter.tags.first(2).compact_blank.each do |t|
            span(style: "color: var(--foreground2); font-size: 0.8em;") { t }
            plain " "
          end
        end
      end
      td(style: "color: var(--foreground2);") { plain letter.created_at.strftime("%b %d") }
      td do
        plain letter.address&.name_line || "—"
      end
      td(style: "color: var(--foreground2);") { plain letter.origin_label }
      td do
        if letter.batch_id.present?
          a(href: letter_batch_path(letter.batch_id), style: "text-decoration: none; color: var(--foreground2);") { "##{letter.batch_id}" }
        else
          plain "—"
        end
      end
      td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
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
