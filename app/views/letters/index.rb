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
    stat_filters
    letters_list
    pagination_section
  end

  private

  attr_reader :letters, :all_letters, :search, :status, :origin, :user_id, :users

  def toolbar
    render Components::Shared::PageToolbar.new(
      title: "Letters",
      jumpcode_path: letters_path,
      search_path: letters_path,
      search_value: search,
      search_placeholder: "Search letters...",
      search_params: { status: status, origin: origin, user_id: user_id },
      action_href: new_letter_path,
      action_label: "+ Send Letter"
    ) do
      render Components::Shared::OriginTabs.new(
        options: { nil => "All", "manual" => "Manual", "bulk_upload" => "Bulk", "queue" => "Queue", "api" => "API" },
        active: origin,
        base_path: ->(params = {}) { letters_path(search: search, status: status, user_id: user_id, **params) },
        preserved_params: { search: search, status: status, user_id: user_id }
      )

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { letters_path(search: search, status: status, origin: origin, user_id: uid) }
        )
      end

      if search.present? || status.present? || origin.present? || user_id.present?
        a(href: letters_path, class: "stat-filter") { "× Clear" }
      end
    end
  end

  def stat_filters
    counts = {
      pending: all_letters.where(aasm_state: :pending).count,
      printed: all_letters.where(aasm_state: :printed).count,
      mailed: all_letters.where(aasm_state: :mailed).count,
      received: all_letters.where(aasm_state: :received).count
    }

    render Components::Shared::StatFilters.new(
      stats: [
        { label: "Pending", count: counts[:pending], color: "yellow", param: "pending" },
        { label: "Printed", count: counts[:printed], param: "printed" },
        { label: "Mailed", count: counts[:mailed], color: "blue", param: "mailed" },
        { label: "Received", count: counts[:received], color: "green", param: "received" },
      ],
      active: status,
      base_path: ->(params = {}) { letters_path(origin: origin, search: search, user_id: user_id, **params) },
      preserved_params: { origin: origin, search: search, user_id: user_id },
      total: letters.respond_to?(:total_count) ? letters.total_count : letters.count
    )
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
          letter.tags.first(2).compact_blank.each do |t|
            span(class: "row-tag") { t }
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
