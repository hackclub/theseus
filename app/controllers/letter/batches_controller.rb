class Letter::BatchesController < BaseBatchesController
  # GET /letter/batches
  def index
    authorize Letter::Batch
    @batches = Letter::Batch.all.order(created_at: :desc)
  end

  # GET /letter/batches/new
  def new
    authorize Letter::Batch
    @batch = Letter::Batch.new
  end

  # GET /letter/batches/:id
  def show
    authorize @batch
  end

  # GET /letter/batches/:id/edit
  def edit
    authorize @batch
  end

  # POST /letter/batches
  def create
    authorize Letter::Batch
    @batch = Letter::Batch.new(batch_params.merge(user: current_user))

    if @batch.save
      redirect_to letter_batch_path(@batch), notice: "Batch was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH /letter/batches/:id
  def update
    authorize @batch
    if @batch.update(batch_params)
      # Update associated letters if the batch hasn't been processed
      if @batch.may_mark_processed?
        @batch.letters.update_all(
          letter_height: @batch.letter_height,
          letter_width: @batch.letter_width,
          letter_weight: @batch.letter_weight,
          letter_mailing_date: @batch.letter_mailing_date,
          letter_mailer_id_id: @batch.letter_mailer_id_id,
          letter_return_address_id: @batch.letter_return_address_id,
          letter_return_address_name: @batch.letter_return_address_name,
        )
      end

      # Always update tags and user facing title on letters
      @batch.letters.update_all(
        tags: @batch.tags,
        user_facing_title: @batch.user_facing_title,
      )

      redirect_to letter_batch_path(@batch), notice: "Batch was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /letter/batches/:id
  def destroy
    authorize @batch
    @batch.destroy
    redirect_to letter_batches_path, notice: "Batch was successfully destroyed."
  end

  def process_form
    authorize @batch, :process_form?
    render :process_letter
  end

  def process_batch
    authorize @batch, :process_batch?
    @batch = Batch.find(params[:id])

    if request.post?
      if letter_batch_params[:letter_mailing_date].blank?
        redirect_to process_letter_batch_path(@batch), alert: "Mailing date is required"
        return
      end

      @batch.letter_mailing_date = letter_batch_params[:letter_mailing_date]
      @batch.save! # Save the mailing date before processing

      # Only require payment account if indicia is selected
      if letter_batch_params[:us_postage_type] == "indicia" || letter_batch_params[:intl_postage_type] == "indicia"
        payment_account = USPS::PaymentAccount.find_by(id: letter_batch_params[:usps_payment_account_id])

        if payment_account.nil?
          redirect_to process_letter_batch_path(@batch), alert: "Please select a valid payment account when using indicia"
          return
        end
      end

      begin
        @batch.process!(
          payment_account: payment_account,
          us_postage_type: letter_batch_params[:us_postage_type],
          intl_postage_type: letter_batch_params[:intl_postage_type],
          template_cycle: letter_batch_params[:template_cycle].compact_blank,
          user_facing_title: letter_batch_params[:user_facing_title],
          include_qr_code: letter_batch_params[:include_qr_code],
        )
        @batch.mark_processed! if @batch.may_mark_processed?
        redirect_to letter_batch_path(@batch), notice: "Batch processed successfully"
      rescue => e
        redirect_to process_letter_batch_path(@batch), alert: "Failed to process batch: #{e.message}"
      end
    end
  end

  def mark_printed
    authorize @batch, :mark_printed?
    if @batch.processed?
      @batch.letters.each do |letter|
        letter.mark_printed! if letter.may_mark_printed?
      end
      flash[:success] = "all letters have been marked as printed!"
      redirect_to letter_batch_path(@batch)
    else
      flash[:alert] = "Cannot mark letters as printed. Batch must be processed."
      redirect_to letter_batch_path(@batch)
    end
  end

  def mark_mailed
    authorize @batch, :mark_mailed?
    if @batch.processed?
      @batch.letters.each do |letter|
        letter.mark_mailed! if letter.may_mark_mailed?
      end
      redirect_to letter_batch_path(@batch), notice: "All letters have been marked as mailed."
    else
      redirect_to letter_batch_path(@batch), alert: "Cannot mark letters as mailed. Batch must be processed."
    end
  end

  def update_costs
    authorize @batch, :update_costs?
    # Calculate counts without saving
    us_letters = @batch.letters.joins(:address).where(addresses: { country: "US" })
    intl_letters = @batch.letters.joins(:address).where.not(addresses: { country: "US" })

    cost_differences = @batch.postage_cost_difference(
      us_postage_type: params[:us_postage_type],
      intl_postage_type: params[:intl_postage_type],
    )

    render json: {
      total_cost: @batch.postage_cost,
      cost_difference: {
        us: cost_differences[:us],
        intl: cost_differences[:intl],
      },
      us_count: us_letters.count,
      intl_count: intl_letters.count,
    }
  end

  private

  def batch_params
    params.require(:letter_batch).permit(
      :csv,
      :letter_template_id,
      :user_facing_title,
      :letter_height,
      :letter_width,
      :letter_weight,
      :letter_mailing_date,
      :letter_mailer_id_id,
      :letter_return_address_id,
      :letter_return_address_name,
      :letter_processing_category,
      tags: [],
    )
  end

  def letter_batch_params
    params.require(:batch).permit(
      :csv,
      :letter_height,
      :letter_width,
      :user_facing_title,
      :letter_weight,
      :letter_mailing_date,
      :letter_processing_category,
      :letter_mailer_id_id,
      :letter_return_address_id,
      :letter_return_address_name,
      :us_postage_type,
      :intl_postage_type,
      :usps_payment_account_id,
      :include_qr_code,
      template_cycle: [],
      tags: [],
    )
  end
end
