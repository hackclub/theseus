class Letter::BatchesController < BaseBatchesController
  # GET /letter/batches
  def index
    authorize Letter::Batch, policy_class: Letter::BatchPolicy
    @batches = policy_scope(Letter::Batch, policy_scope_class: Letter::BatchPolicy::Scope).order(created_at: :desc)
    render Views::Letter::Batches::Index.new(batches: @batches)
  end

  # GET /letter/batches/new
  def new
    authorize Letter::Batch, policy_class: Letter::BatchPolicy
    @batch = Letter::Batch.new
    render Views::Letter::Batches::New.new(batch: @batch)
  end

  # GET /letter/batches/:id
  def show
    authorize @batch, policy_class: Letter::BatchPolicy
    if @batch.purchasing? || @batch.generating_labels?
      redirect_to processing_letter_batch_path(@batch)
      return
    end
    render Views::Letter::Batches::Show.new(batch: @batch)
  end

  # GET /letter/batches/:id/edit
  def edit
    authorize @batch, policy_class: Letter::BatchPolicy
    render Views::Letter::Batches::Edit.new(batch: @batch)
  end

  # GET /letter/batches/:id/map
  def map_fields
    authorize @batch, policy_class: Letter::BatchPolicy
    @csv_headers = @batch.csv_headers
    @sample_row = @batch.csv_sample_row
    render Views::Letter::Batches::Map.new(batch: @batch, csv_headers: @csv_headers, sample_row: @sample_row)
  end

  # GET /letter/batches/:id/processing
  def processing
    authorize @batch, :show?, policy_class: Letter::BatchPolicy
    @cells = @batch.letters.includes(:address).order(:id).map do |letter|
      state = case letter.indicia_state
              when "purchased" then "purchased"
              when "failed" then "failed"
              else "pending"
              end
      icon = case state
             when "purchased" then "✓"
             when "failed" then "x"
             else " "
             end
      { id: letter.id, state: state, title: letter.public_id, icon: icon }
    end
    # renders processing.html.erb
  end

  # POST /letter/batches/:id/set_mapping
  def set_mapping
    authorize @batch, policy_class: Letter::BatchPolicy
    @batch.update!(field_mapping: params[:field_mapping].to_unsafe_h)
    importer = LetterBatchImporter.new(@batch)
    validation = importer.validate

    if validation.any? { |r| r[:status] == :error }
      render Views::Letter::Batches::Validate.new(batch: @batch, validation: validation)
    else
      count = importer.call
      redirect_to process_confirm_letter_batch_path(@batch), notice: "Imported #{count} letters."
    end
  rescue => e
    redirect_to map_fields_letter_batch_path(@batch), alert: "Mapping failed: #{e.message}"
  end

  # POST /letter/batches
  def create
    authorize Letter::Batch, policy_class: Letter::BatchPolicy
    @batch = Letter::Batch.new(batch_params.merge(user: current_user))

    if @batch.save
      redirect_to map_fields_letter_batch_path(@batch)
    else
      render Views::Letter::Batches::New.new(batch: @batch), status: :unprocessable_entity
    end
  end

  # PATCH /letter/batches/:id
  def update
    authorize @batch, policy_class: Letter::BatchPolicy
    if @batch.update(batch_params)
      validate_postage_types
      if @batch.errors.any?
        render :edit, status: :unprocessable_entity
        return
      end

      # Update associated letters if the batch hasn't been processed
      if @batch.may_mark_processed?
        @batch.letters.update_all(
          height: @batch.letter_height,
          width: @batch.letter_width,
          weight: @batch.letter_weight,
          mailing_date: @batch.letter_mailing_date,
          usps_mailer_id_id: @batch.letter_mailer_id_id,
          return_address_id: @batch.letter_return_address_id,
          return_address_name: @batch.letter_return_address_name,
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
    authorize @batch, policy_class: Letter::BatchPolicy
    @batch.destroy
    redirect_to letter_batches_path, notice: "Batch was successfully destroyed."
  end

  def process_form
    authorize @batch, :process_form?, policy_class: Letter::BatchPolicy
    render Views::Letter::Batches::Process.new(batch: @batch)
  end

  def process_batch
    authorize @batch, :process_batch?, policy_class: Letter::BatchPolicy

    if letter_batch_params[:letter_mailing_date].blank?
      redirect_to process_confirm_letter_batch_path(@batch), alert: "Mailing date is required"
      return
    end

    # Validate payment accounts if indicia selected
    if letter_batch_params[:us_postage_type] == "indicia" || letter_batch_params[:intl_postage_type] == "indicia"
      authorize @batch, :process_batch_with_indicia?, policy_class: Letter::BatchPolicy

      unless USPS::PaymentAccount.exists?(id: letter_batch_params[:usps_payment_account_id])
        redirect_to process_confirm_letter_batch_path(@batch), alert: "Please select a valid USPS payment account"
        return
      end

      unless current_user.hcb_payment_accounts.exists?(id: letter_batch_params[:hcb_payment_account_id])
        redirect_to process_confirm_letter_batch_path(@batch), alert: "Please select an HCB payment account"
        return
      end
    end

    # Save options and mailing date, then enqueue
    @batch.update!(
      letter_mailing_date: letter_batch_params[:letter_mailing_date],
      process_options: {
        us_postage_type: letter_batch_params[:us_postage_type],
        intl_postage_type: letter_batch_params[:intl_postage_type],
        usps_payment_account_id: letter_batch_params[:usps_payment_account_id],
        hcb_payment_account_id: letter_batch_params[:hcb_payment_account_id],
        non_machinable: letter_batch_params[:non_machinable],
        template_cycle: letter_batch_params[:template_cycle].to_s.split(",").compact_blank.presence ||
          [SnailMail::PhlexService.templates_for_size(:standard).first].compact,
        user_facing_title: letter_batch_params[:user_facing_title],
        include_qr_code: letter_batch_params[:include_qr_code],
      }
    )

    BatchProcessJob.perform_later(@batch.id)
    redirect_to processing_letter_batch_path(@batch)
  end

  def mark_printed
    authorize @batch, :mark_printed?, policy_class: Letter::BatchPolicy
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
    authorize @batch, :mark_mailed?, policy_class: Letter::BatchPolicy
    if @batch.processed?
      @batch.letters.each do |letter|
        letter.mark_mailed! if letter.may_mark_mailed?
      end
      User::UpdateTasksJob.perform_later(current_user)
      redirect_to letter_batch_path(@batch), notice: "All letters have been marked as mailed."
    else
      redirect_to letter_batch_path(@batch), alert: "Cannot mark letters as mailed. Batch must be processed."
    end
  end

  def retry_failed
    authorize @batch, :process_batch?, policy_class: Letter::BatchPolicy
    @batch.letters.where(indicia_state: "failed").update_all(indicia_state: nil, indicia_error: nil)
    @batch.update!(process_error: nil)

    # Fix empty template_cycle if that's what caused the failure
    opts = @batch.process_options || {}
    if opts["template_cycle"].blank?
      opts["template_cycle"] = [SnailMail::PhlexService.templates_for_size(:standard).first].compact
      @batch.update!(process_options: opts)
    end

    BatchProcessJob.perform_later(@batch.id)
    redirect_to processing_letter_batch_path(@batch)
  end

  def refund_overpayment
    authorize @batch, :process_batch?, policy_class: Letter::BatchPolicy
    charged = @batch.hcb_transfer_amount_cents.to_i
    spent = (@batch.letters.where(indicia_state: "purchased").joins(:usps_indicium).sum("usps_indicia.cost") * 100).ceil
    overpaid = charged - spent

    if overpaid <= 0
      redirect_to processing_letter_batch_path(@batch), alert: "Nothing to refund."
      return
    end

    hcb_account = @batch.hcb_payment_account
    HCB::PaymentAccount.refund_to_organization!(
      organization_id: hcb_account.organization_id,
      amount_cents: overpaid,
      name: "Refund for #{@batch.public_id}",
      memo: "[theseus] overpayment refund",
    )

    redirect_to processing_letter_batch_path(@batch), notice: "Refunded $#{'%.2f' % (overpaid / 100.0)}"
  rescue => e
    redirect_to processing_letter_batch_path(@batch), alert: "Refund failed: #{e.message}"
  end

  def update_costs
    authorize @batch, :update_costs?, policy_class: Letter::BatchPolicy
    # Calculate counts without saving
    us_letters = @batch.letters.joins(:address).where(addresses: { country: "US" })
    intl_letters = @batch.letters.joins(:address).where.not(addresses: { country: "US" })

    non_machinable = ActiveModel::Type::Boolean.new.cast(params[:non_machinable])

    cost_differences = @batch.postage_cost_difference(
      us_postage_type: params[:us_postage_type],
      intl_postage_type: params[:intl_postage_type],
      non_machinable: non_machinable,
    )

    render json: {
      total_cost: @batch.postage_cost(non_machinable: non_machinable),
      cost_difference: {
        us: cost_differences[:us],
        intl: cost_differences[:intl],
      },
      us_count: us_letters.count,
      intl_count: intl_letters.count,
    }
  end

  def regenerate_form
    authorize @batch, :process_batch?, policy_class: Letter::BatchPolicy
    render :regenerate_labels
  end

  def regenerate_labels
    authorize @batch, :process_batch?, policy_class: Letter::BatchPolicy
    @batch.regenerate_labels!(
      template_cycle: letter_batch_params[:template_cycle].to_s.split(",").compact_blank,
      include_qr_code: letter_batch_params[:include_qr_code],
    )
    redirect_to letter_batch_path(@batch), notice: "Labels regenerated successfully"
  end

  def import_with_skip
    authorize @batch, :update?, policy_class: Letter::BatchPolicy
    count = LetterBatchImporter.new(@batch).call(skip_invalid: true)
    redirect_to process_confirm_letter_batch_path(@batch), notice: "Imported #{count} letters (skipped invalid rows)."
  end

  private

  def batch_params
    params.require(:letter_batch).permit(
      :csv,
      :addresses_data,
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
      :hcb_payment_account_id,
      :include_qr_code,
      :print_immediately,
      :template_cycle,
      :non_machinable,
      tags: [],
    )
  end

  def validate_postage_types
    return unless @batch.letter_return_address&.us?

    us_postage_type = batch_params[:us_postage_type]
    intl_postage_type = batch_params[:intl_postage_type]

    if us_postage_type.present? && !%w[stamps indicia].include?(us_postage_type)
      @batch.errors.add(:us_postage_type, "must be either 'stamps' or 'indicia'")
    end

    if intl_postage_type.present? && !%w[stamps indicia].include?(intl_postage_type)
      @batch.errors.add(:intl_postage_type, "must be either 'stamps' or 'indicia'")
    end
  end
end
