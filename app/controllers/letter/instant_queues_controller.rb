class Letter::InstantQueuesController < Letter::QueuesController
  before_action :set_letter_queue, only: %i[ show edit update destroy ]

  def new
    @letter_queue = Letter::InstantQueue.new
    render Views::Letter::InstantQueues::New.new(queue: @letter_queue)
  end

  def edit
    render Views::Letter::InstantQueues::Edit.new(queue: @letter_queue)
  end

  def create
    @letter_queue = Letter::InstantQueue.new(letter_queue_params.merge(user: current_user))

    if @letter_queue.save
      redirect_to @letter_queue, notice: "Queue was successfully created."
    else
      render Views::Letter::InstantQueues::New.new(queue: @letter_queue), status: :unprocessable_entity
    end
  end

  def update
    if @letter_queue.update(letter_queue_params)
      redirect_to @letter_queue, notice: "Queue was successfully updated."
    else
      render Views::Letter::InstantQueues::Edit.new(queue: @letter_queue), status: :unprocessable_entity
    end
  end

  def show
    letter_counts = @letter_queue.letters
                      .group(:aasm_state)
                      .count

    letters = @letter_queue.letters.order(created_at: :desc)
    letters = letters.search(params[:search]) if params[:search].present?
    letters = letters.where(aasm_state: params[:status]) if params[:status].present?

    render Views::Letter::InstantQueues::Show.new(
      queue: @letter_queue,
      letters: letters,
      batches: [],
      letter_counts: letter_counts,
      search: params[:search],
      status: params[:status]
    )
  end

  private

  def set_letter_queue
    @letter_queue = Letter::InstantQueue.find_by!(slug: params[:id])
  end

  def letter_queue_params
    params.require(:letter_instant_queue).permit(
      :name,
      :type,
      :letter_height,
      :letter_width,
      :letter_weight,
      :letter_processing_category,
      :letter_mailer_id_id,
      :letter_return_address_id,
      :letter_return_address_name,
      :user_facing_title,
      :template,
      :postage_type,
      :usps_payment_account_id,
      :hcb_payment_account_id,
      :include_qr_code,
      tags: [],
    )
  end
end
