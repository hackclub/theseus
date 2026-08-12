# frozen_string_literal: true

class UserTasks
  CACHE_TTL = 5.minutes

  def initialize(user)
    @user = user
  end

  def count
    all.size
  end

  def all
    @all ||= queued_letters + pending_batches + printed_letters
  end

  def all_cached
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { all }
  end

  def count_cached
    cached = Rails.cache.read(cache_key)
    cached ? cached.size : count
  end

  def warm_cache!
    Rails.cache.write(cache_key, all, expires_in: CACHE_TTL)
    all
  end

  def cache_key = "user_tasks/#{@user.id}"

  private

  def queued_letters
    @user.letter_queues
      .select("letter_queues.name, letter_queues.slug, COUNT(letters.id) as letter_count")
      .joins(:letters)
      .where(letters: { aasm_state: "queued" })
      .group("letter_queues.name, letter_queues.slug")
      .map do |queue|
      {
        type: "Queues with waiting letters",
        name: queue.name,
        subtitle: "#{queue.letter_count} #{"letter".pluralize(queue.letter_count)} queued",
        count: queue.letter_count,
        link: Rails.application.routes.url_helpers.letter_queue_path(queue.slug, anchor: "letters")
      }
    end
  end

  def pending_batches
    @user.batches
      .where(aasm_state: "fields_mapped")
      .map do |batch|
      {
        type: "Batches awaiting processing",
        name: "#{batch.class.name.split("::").first} batch ##{batch.id}",
        subtitle: "#{batch.origin}#{batch.tags.any? ? " [#{batch.tags.join(", ")}]" : nil}",
        link: batch_link(batch)
      }
    end
  end

  def printed_letters
    @user.letters
      .printed
      .includes(:address)
      .map do |letter|
      {
        type: "Letters printed but not marked mailed",
        name: "Letter #{letter.public_id} – #{letter.user_facing_title || letter.tags.join(", ")}",
        subtitle: "to #{letter.address.name_line}",
        link: Rails.application.routes.url_helpers.letter_path(letter)
      }
    end
  end

  def batch_link(batch)
    helpers = Rails.application.routes.url_helpers
    case batch
    when Warehouse::Batch
      helpers.process_confirm_warehouse_batch_path(batch)
    when Letter::Batch
      helpers.process_confirm_letter_batch_path(batch)
    else
      helpers.batch_path(batch)
    end
  end
end
