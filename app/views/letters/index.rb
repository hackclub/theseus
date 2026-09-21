# frozen_string_literal: true

class Views::Letters::Index < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  def initialize(letters:, all_letters:, letter_state_counts: {}, search: nil, status: nil, origin: nil, user_id: nil, users: [])
    @letters = letters
    @all_letters = all_letters
    @letter_state_counts = letter_state_counts
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

  attr_reader :letters, :all_letters, :letter_state_counts, :search, :status, :origin, :user_id, :users

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
    render Components::Shared::StatFilters.new(
      stats: [
        { label: "Pending", count: letter_state_counts.fetch("pending", 0), color: "yellow", param: "pending" },
        { label: "Printed", count: letter_state_counts.fetch("printed", 0), param: "printed" },
        { label: "Mailed", count: letter_state_counts.fetch("mailed", 0), color: "blue", param: "mailed" },
        { label: "Received", count: letter_state_counts.fetch("received", 0), color: "green", param: "received" }
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
      section(class: "empty-state") do
        p(class: "m-0") { "No letters found." }
        if !(search.present? || status.present?)
          a(href: new_letter_path) { button(class: "btn-success") { "Send Letter" } }
        end
      end
    end
  end

  def render_letter_row(letter)
    tr do
      td do
        a(href: letter_path(letter), class: "no-underline") do
          plain letter.public_id
        end
        if letter.tags.present?
          letter.tags.first(2).compact_blank.each do |t|
            span(class: "row-tag") { t }
          end
        end
      end
      td(class: "text-muted") { plain letter.created_at.strftime("%b %d") }
      td do
        plain letter.address&.name_line || "—"
      end
      td(class: "text-muted") { plain letter.origin_label }
      td do
        if letter.batch_id.present?
          a(href: letter_batch_path(letter.batch_id), class: "no-underline text-muted") { "##{letter.batch_id}" }
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
