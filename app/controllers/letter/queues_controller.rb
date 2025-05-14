class Letter::QueuesController < ApplicationController
  before_action :set_letter_queue, only: %i[ show edit update destroy batch ]
  skip_after_action :verify_authorized
  # GET /letter/queues or /letter/queues.json
  def index
    @letter_queues = Letter::Queue.all
  end

  # GET /letter/queues/1 or /letter/queues/1.json
  def show
    @letters = @letter_queue.letters.queued
    @batches = @letter_queue.letter_batches
  end

  # GET /letter/queues/new
  def new
    @letter_queue = Letter::Queue.new
  end

  # GET /letter/queues/1/edit
  def edit
  end

  # POST /letter/queues or /letter/queues.json
  def create
    @letter_queue = letter_queue_class.new(letter_queue_params.merge(user: current_user))

    respond_to do |format|
      if @letter_queue.save
        format.html { redirect_to @letter_queue, notice: "Queue was successfully created." }
        format.json { render :show, status: :created, location: @letter_queue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @letter_queue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /letter/queues/1 or /letter/queues/1.json
  def update
    respond_to do |format|
      if @letter_queue.update(letter_queue_params)
        format.html { redirect_to @letter_queue, notice: "Queue was successfully updated." }
        format.json { render :show, status: :ok, location: @letter_queue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @letter_queue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /letter/queues/1 or /letter/queues/1.json
  def destroy
    @letter_queue.destroy!

    respond_to do |format|
      format.html { redirect_to letter_queues_path, status: :see_other, notice: "Queue was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def batch
    authorize @letter_queue
    unless @letter_queue.letters.any?
      flash[:error] = "no letters?"
      redirect_to @letter_queue
    end
    batch = @letter_queue.make_batch(user: current_user)
    flash[:success] = "now do something with it!"
    redirect_to process_letter_batch_path batch
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_letter_queue
    @letter_queue = Letter::Queue.find_by!(slug: params[:id])
  end

  def letter_queue_class
    type = params[:letter_queue]&.dig(:type) || params[:letter_instant_queue]&.dig(:type)
    case type
    when "Letter::InstantQueue"
      Letter::InstantQueue
    else
      Letter::Queue
    end
  end

  # Only allow a list of trusted parameters through.
  def letter_queue_params
    params.require(:letter_queue).permit(
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
      :include_qr_code,
      :letter_mailing_date,
      tags: [],
    )
  end
end
