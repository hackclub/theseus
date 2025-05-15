class User
  class UpdateTasksJob < ApplicationJob
    queue_as :default

    def perform(user)
      tasks = gather_tasks(user)
      Rails.cache.write("user_tasks/#{user.id}", tasks, expires_in: 5.minutes)
      tasks
    end

    private

    def gather_tasks(user)
      queues = user.letter_queues
        .select("letter_queues.name, letter_queues.slug, COUNT(letters.id) as letter_count")
        .joins(:letters)
        .where(letters: { aasm_state: "queued" })
        .group("letter_queues.name, letter_queues.slug")
        .map do |queue|
        {
          type: "queues with waiting letters",
          name: queue.name,
          subtitle: "#{queue.letter_count} #{"letter".pluralize(queue.letter_count)} queued...",
          count: queue.letter_count,
          link: Rails.application.routes.url_helpers.letter_queue_path(queue.slug, anchor: "letters"),
        }
      end

      batches = user.batches
        .where(aasm_state: "fields_mapped").map do |batch|
        {
          type: "Batches awaiting processing",
          name: "#{batch.class.name.split("::").first} batch ##{batch.id}",
          subtitle: "#{batch.origin}#{batch.tags.any? ? " [#{batch.tags.join(", ")}]" : nil}",
          link: case batch
          when Warehouse::Batch
            Rails.application.routes.url_helpers.process_warehouse_batch_path(batch)
          when Letter::Batch
            Rails.application.routes.url_helpers.process_letter_batch_path(batch)
          else
            Rails.application.routes.url_helpers.process_batch_path(batch)
          end,
        }
      end

      letters = user.letters
        .printed
        .includes(:address)
        .map do |letter|
        {
          type: "Letters printed but not marked mailed",
          name: "Letter #{letter.public_id} – #{letter.user_facing_title || letter.tags.join(", ")}",
          subtitle: "to #{letter.address.name_line}",
          link: Rails.application.routes.url_helpers.letter_path(letter),
        }
      end

      queues + batches + letters
    end
  end
end
