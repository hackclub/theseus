# frozen_string_literal: true

class Views::Warehouse::Batches::Index < Views::Base
  def initialize(batches:, search: nil, status: nil, user_id: nil, users: [])
    @batches = batches
    @search = search
    @status = status
    @user_id = user_id
    @users = users
  end

  def view_template
    toolbar
    stat_filters
    batches_table
  end

  private

  attr_reader :batches, :search, :status, :user_id, :users

  def toolbar
    render Components::Shared::PageToolbar.new(
      title: "Warehouse Batches",
      jumpcode_path: warehouse_batches_path,
      search_path: warehouse_batches_path,
      search_value: search,
      search_placeholder: "Search batches...",
      search_params: { user_id: user_id, status: status },
      action_href: new_warehouse_batch_path,
      action_label: "+ New Batch"
    ) do
      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { warehouse_batches_path(search: search, status: status, user_id: uid) }
        )
      end

      if search.present? || user_id.present? || status.present?
        a(href: warehouse_batches_path, class: "clear-filter-link") { "× Clear" }
      end
    end
  end

  def stat_filters
    counts = {
      awaiting_field_mapping: batches.where(aasm_state: :awaiting_field_mapping).count,
      fields_mapped: batches.where(aasm_state: :fields_mapped).count,
      processed: batches.where(aasm_state: :processed).count
    }

    render Components::Shared::StatFilters.new(
      stats: [
        { label: "Awaiting Mapping", count: counts[:awaiting_field_mapping], color: "yellow", param: "awaiting_field_mapping" },
        { label: "Fields Mapped", count: counts[:fields_mapped], color: "blue", param: "fields_mapped" },
        { label: "Processed", count: counts[:processed], color: "green", param: "processed" }
      ],
      active: status,
      base_path: ->(status: nil, **) { warehouse_batches_path(search: search, status: status, user_id: user_id) },
      total: batches.count
    )
  end

  def filtered_batches = @filtered_batches ||= status.present? ? batches.where(aasm_state: status) : batches

  def batches_table
    if filtered_batches.any?
      table do
        thead do
          tr do
            th { "ID" }
            th { "Date" }
            th { "Template" }
            th { "Addresses" }
            th { "Orders" }
            th { "Status" }
          end
        end
        tbody do
          filtered_batches.each { |batch| render_batch_row(batch) }
        end
      end
    else
      blankslate
    end
  end

  def render_batch_row(batch)
    tr do
      td do
        a(href: warehouse_batch_path(batch), class: "no-underline") do
          plain "##{batch.id}"
        end
        if batch.tags.any?
          plain " "
          batch.tags.first(2).compact_blank.each do |t|
            span(class: "batch-tag-chip") { t }
            plain " "
          end
        end
      end
      td(class: "text-muted") { plain batch.created_at.strftime("%b %d") }
      td { plain batch.warehouse_template&.name || "—" }
      td(class: "text-muted") { plain batch.address_count&.to_s || "0" }
      td(class: "text-muted") { plain batch.orders.size.to_s }
      td { render Components::Shared::StatusBadge.new(status: batch.aasm.current_state, type: :batch) }
    end
  end

  def blankslate
    section(class: "empty-state") do
      h2(class: "m-0") { "📦 No warehouse batches yet" }
      p(class: "text-muted") { "Create a batch to ship items to multiple addresses at once." }
      a(href: new_warehouse_batch_path, class: "btn-success") { "+ New Batch" }
    end
  end
end
