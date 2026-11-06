# frozen_string_literal: true

class BatchStaleCheckJob < ApplicationJob
  queue_as :default

  def perform
    Letter::Batch
      .where(aasm_state: %w[purchasing generating_labels])
      .where(updated_at: ...30.minutes.ago)
      .find_each do |batch|
        batch.update!(process_error: "Batch appears stuck (no progress for 30+ minutes). Retry or contact support.")
        batch.mark_failed! if batch.may_mark_failed?
        Sentry.capture_message("Stale batch detected", extra: { batch_id: batch.id, state: batch.aasm_state })
      end
  end
end
