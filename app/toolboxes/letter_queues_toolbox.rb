class LetterQueuesToolbox < ApplicationToolbox
  default_param :queue_id, :string, "Queue slug", except: [ :list, :create ]

  tool "List your letter queues — templates for bulk letter creation where external systems push addresses in and letters are held until batched", access: :read do
    param :page, :integer, "Page number", optional: true
  end
  def list
    @queues = paginate(current_user.letter_queues.order(created_at: :desc))
    @letter_counts = Letter.where(letter_queue_id: @queues.map(&:id))
                           .group(:letter_queue_id, :aasm_state)
                           .count
  end

  tool "Show details of a letter queue including letter counts by state and batch count", access: :read do
  end
  def show
    @queue = current_user.letter_queues.find_by!(slug: params[:queue_id])
    @letter_counts = @queue.letters.group(:aasm_state).count
    @batches_count = @queue.letter_batches.count
  end

  tool "Create a new letter queue for bulk letter creation from external address submissions", access: :write do
    param :name, :string, "Queue name"
    param :letter_height, :number, "Letter height in inches"
    param :letter_width, :number, "Letter width in inches"
    param :letter_weight, :number, "Letter weight in ounces"
    param :letter_processing_category, :string, "Mail class: letter (standard envelope) or flat (large envelope)", enum: %w[letter flat]
    param :letter_mailer_id_id, :integer, "USPS Mailer ID for letters in this queue (use postage_mailer_ids to find)"
    param :letter_return_address_id, :integer, "Return address for letters in this queue (use return_addresses_list to find)"
    param :tags, [ :string ], "Tags for letters in this queue"
    param :postage_type, :string, "Postage method: stamps (physical), indicia (USPS electronic postage), or international_origin", optional: true
    param :user_facing_title, :string, "User-facing title", optional: true
    param :include_qr_code, :boolean, "Include QR code on letters", optional: true
  end
  def create
    @queue = Letter::Queue.new(
      params.permit(
        :name, :letter_height, :letter_width, :letter_weight,
        :letter_processing_category, :letter_mailer_id_id,
        :letter_return_address_id, :postage_type,
        :user_facing_title, :include_qr_code, tags: []
      ).merge(user: current_user)
    )
    @queue.save!
    render :show
  end

  tool "Pull queued letters from this queue into a new batch for printing and mailing", access: :write do
    param :limit, :integer, "Max letters to include in the batch", optional: true
  end
  def make_batch
    @queue = current_user.letter_queues.find_by!(slug: params[:queue_id])
    halt error: "No queued letters in this queue" unless @queue.letters.queued.any?
    batch = @queue.make_batch(user: current_user, limit: params[:limit]&.to_i)
    render json: {
      batch_id: batch.id,
      letter_count: batch.letters.count,
      state: batch.aasm_state,
      created_at: batch.created_at
    }
  end
end
