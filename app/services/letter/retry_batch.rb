# frozen_string_literal: true

# Reset failed letters in a batch and re-enqueue for processing.
class Letter::RetryBatch
  def initialize(batch:)
    @batch = batch
  end

  def call
    raise "Batch is not in a failed state." unless @batch.failed?

    @batch.with_lock do
      @batch.letters.where(indicia_state: "failed").update_all(indicia_state: nil, indicia_error: nil)
      @batch.update!(process_error: nil)

      opts = @batch.process_options || {}
      if opts["template_cycle"].blank?
        opts["template_cycle"] = [SnailMail::PhlexService.templates_for_size(:standard).first].compact
        @batch.update!(process_options: opts)
      end
    end

    BatchProcessJob.perform_later(@batch.id)
  end
end
