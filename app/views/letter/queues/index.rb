# frozen_string_literal: true

class Views::Letter::Queues::Index < Views::Base
  def initialize(letter_queues:, all_queues:, letter_counts:, user_id: nil, queue_type: nil, users: [])
    @letter_queues = letter_queues
    @all_queues = all_queues
    @letter_counts = letter_counts
    @user_id = user_id
    @queue_type = queue_type
    @users = users
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Letter Queues",
      jumpcode_path: letter_queues_path,
      action_href: new_letter_queue_path,
      action_label: "+ Batch Queue"
    ) do
      render Components::Shared::OriginTabs.new(
        options: { nil => "All", "batch" => "Batch", "instant" => "Instant" },
        active: queue_type,
        base_path: ->(p = {}) { letter_queues_path(**preserved_params.merge(p)) },
        preserved_params: preserved_params
      )

      admin_tool do
        render Components::Shared::UserPicker.new(
          users: users,
          selected_user_id: user_id,
          path_builder: ->(uid) { letter_queues_path(user_id: uid, queue_type: queue_type) }
        )
      end

      a(href: new_letter_instant_queue_path) do
        button(class: "btn-info") { "+ Instant Queue" }
      end

      admin_tool do
        button_to mark_printed_instants_mailed_letter_queues_path, method: :post, style: "display: inline;" do
          button(class: "btn-danger btn-sm") { "Mark printed instants mailed" }
        end
      end

      if user_id.present? || queue_type.present?
        a(href: letter_queues_path, style: "color: GrayText; white-space: nowrap;") { "× Clear" }
      end
    end

    if sorted_queues.any?
      queue_table
    else
      blankslate
    end
  end

  private

  attr_reader :letter_queues, :all_queues, :letter_counts, :user_id, :queue_type, :users

  def preserved_params
    { user_id: user_id, queue_type: queue_type }.compact
  end

  def queue_table
    table do
      thead do
        tr do
          th { "Name" }
          th { "Type" }
          th { "Queued" }
          th { "Printed" }
          th { "Mailed" }
          th { "Total" }
          th { "Status" }
        end
      end
      tbody do
        sorted_queues.each do |queue|
          is_instant = queue.is_a?(::Letter::InstantQueue)
          href = is_instant ? letter_instant_queue_path(queue, status: :printed) : letter_queue_path(queue, status: :queued)
          queued  = count_for(queue, "queued")
          printed = count_for(queue, "printed")
          mailed  = count_for(queue, "mailed")
          total   = queued + printed + mailed + count_for(queue, "pending") + count_for(queue, "received")
          action  = is_instant ? printed : queued

          tr do
            td do
              a(href: href, style: "text-decoration: none; font-weight: 500;") { queue.name }
            end
            td do
              if is_instant
                span(class: "badge badge-success") { "Instant" }
              else
                span(class: "badge badge-info") { "Batch" }
              end
            end
            td(style: queued > 0 ? "color: var(--blue);" : "color: GrayText;") do
              plain fmt(queued)
            end
            td(style: printed > 0 ? "color: var(--green);" : "color: GrayText;") do
              plain fmt(printed)
            end
            td(class: "text-muted") { plain fmt(mailed) }
            td { plain fmt(total) }
            td do
              if action > 0
                label = is_instant ? "#{fmt(action)} awaiting mail" : "#{fmt(action)} queued"
                span(class: is_instant ? "badge badge-success" : "badge badge-info") { label }
              else
                span(class: "text-muted") { "Idle" }
              end
            end
          end
        end
      end
    end
  end

  def sorted_queues
    @sorted_queues ||= letter_queues.sort_by do |q|
      if q.is_a?(::Letter::InstantQueue)
        printed = count_for(q, "printed")
        printed > 0 ? [1, -printed] : [2, q.name.downcase]
      else
        queued = count_for(q, "queued")
        queued > 0 ? [0, -queued] : [2, q.name.downcase]
      end
    end
  end

  def blankslate
    section(style: "text-align: center; padding: 2rem;") do
      h2(style: "margin: 0;") { "No queues found" }
      if queue_type.present? || user_id.present?
        p(class: "text-muted") { "Try adjusting your filters." }
      else
        p(class: "text-muted") { "Create a queue to get started." }
        a(href: new_letter_queue_path) { button(class: "btn-success") { "New Queue" } }
      end
    end
  end

  def count_for(queue, state)
    letter_counts[[queue.id, state]] || 0
  end

  def fmt(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
