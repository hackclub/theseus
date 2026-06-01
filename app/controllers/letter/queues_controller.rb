class Letter::QueuesController < ApplicationController
  before_action :set_letter_queue, only: %i[ show edit update destroy batch ]
  skip_after_action :verify_authorized
  def index
    authorize Letter::Queue, policy_class: Letter::QueuePolicy
    all_queues = policy_scope(Letter::Queue, policy_scope_class: Letter::QueuePolicy::Scope)

    filtered = all_queues

    is_admin = current_user&.is_admin?

    user_id = is_admin ? params[:user_id] : nil
    filtered = filtered.where(user_id: user_id) if user_id.present?
    users = is_admin ? User.where(id: all_queues.select(:user_id).distinct).order(:email) : []

    filtered = filtered.includes(:user) if is_admin

    if params[:queue_type] == "batch"
      filtered = filtered.where.not(type: "Letter::InstantQueue")
    elsif params[:queue_type] == "instant"
      filtered = filtered.where(type: "Letter::InstantQueue")
    end

    letter_counts = Letter.where(letter_queue_id: filtered.select(:id))
                          .group(:letter_queue_id, :aasm_state)
                          .count

    render Views::Letter::Queues::Index.new(
      letter_queues: filtered.to_a,
      all_queues: all_queues,
      letter_counts: letter_counts,
      user_id: user_id,
      queue_type: params[:queue_type],
      users: users
    )
  end

  def show
    letter_counts = @letter_queue.letters
                      .group(:aasm_state)
                      .count

    letters = @letter_queue.letters.order(created_at: :desc)
    letters = letters.search(params[:search]) if params[:search].present?
    letters = letters.where(aasm_state: params[:status]) if params[:status].present?

    @batches = @letter_queue.letter_batches.order(created_at: :desc)

    render Views::Letter::Queues::Show.new(
      queue: @letter_queue,
      letters: letters,
      batches: @batches,
      letter_counts: letter_counts,
      search: params[:search],
      status: params[:status]
    )
  end

  def new
    @letter_queue = Letter::Queue.new
    render Views::Letter::Queues::New.new(queue: @letter_queue)
  end

  def edit
    render Views::Letter::Queues::Edit.new(queue: @letter_queue)
  end

  def create
    @letter_queue = letter_queue_class.new(letter_queue_params.merge(user: current_user))

    if @letter_queue.save
      redirect_to @letter_queue, notice: "Queue was successfully created."
    else
      render Views::Letter::Queues::New.new(queue: @letter_queue), status: :unprocessable_entity
    end
  end

  def update
    if @letter_queue.update(letter_queue_params)
      redirect_to @letter_queue, notice: "Queue was successfully updated."
    else
      render Views::Letter::Queues::Edit.new(queue: @letter_queue), status: :unprocessable_entity
    end
  end

  def destroy
    @letter_queue.destroy!
    redirect_to letter_queues_path, status: :see_other, notice: "Queue was successfully destroyed."
  end

  def batch
    authorize @letter_queue
    unless @letter_queue.letters.any?
      flash[:error] = "no letters?"
      redirect_to @letter_queue
      return
    end
    limit = params[:limit].presence&.to_i
    batch = @letter_queue.make_batch(user: current_user, limit:)
    User::UpdateTasksJob.perform_later(current_user)
    flash[:success] = "now do something with it!"
    redirect_to process_confirm_letter_batch_path(batch, uft: @letter_queue.user_facing_title, template: @letter_queue.template)
  end

  def mark_printed_instants_mailed
    authorize Letter::Queue

    # Find all letters with "printed" status in any instant letter queue
    printed_letters = Letter.joins(:queue)
      .where(letter_queues: { type: "Letter::InstantQueue" })
      .where(aasm_state: "printed")

    if printed_letters.empty?
      flash[:notice] = "No printed letters found in instant queues."
      redirect_to letter_queues_path
      return
    end

    # Mark all printed letters as mailed
    marked_count = 0
    failed_letters = []

    printed_letters.each do |letter|
      begin
        letter.mark_mailed!
        marked_count += 1
      rescue => e
        failed_letters << "#{letter.public_id} (#{e.message})"
      end
    end

    # Update user tasks after marking letters as mailed
    User::UpdateTasksJob.perform_later(current_user) if marked_count > 0

    if failed_letters.any?
      flash[:alert] = "Marked #{marked_count} letters as mailed, but failed to mark #{failed_letters.count} letters: #{failed_letters.join(", ")}"
    else
      flash[:success] = "Successfully marked #{marked_count} letters as mailed from instant queues."
    end

    redirect_to letter_queues_path
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
