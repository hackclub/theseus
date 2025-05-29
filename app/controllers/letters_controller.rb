class LettersController < ApplicationController
  before_action :set_letter, except: %i[ index new create ]

  # GET /letters
  def index
    authorize Letter
    # Get all letters with their associations using policy scope
    @all_letters = policy_scope(Letter).includes(:batch, :address, :usps_mailer_id, :label_attachment, :label_blob)
      .where.not(aasm_state: "queued")
      .order(created_at: :desc)

    # Get unbatched letters with pagination
    @unbatched_letters = @all_letters.not_in_batch.page(params[:page]).per(20)

    # Get batched letters grouped by batch
    @batched_letters = @all_letters.in_batch.group_by(&:batch)
  end

  # GET /letters/1
  def show
    authorize @letter
    @available_templates = SnailMail::Service.available_templates
  end

  # GET /letters/new
  def new
    authorize Letter
    @letter = Letter.new
    @letter.return_address = current_user.home_return_address || ReturnAddress.first
    @letter.build_address
  end

  # GET /letters/1/edit
  def edit
    authorize @letter
    # If letter doesn't have a return address already, don't build one
    # Let the user select one from the dropdown
  end

  # POST /letters
  def create
    @letter = Letter.new(letter_params.merge(user: current_user))
    authorize @letter

    # Set postage type to international_origin if return address is not US
    if @letter.return_address && @letter.return_address.country != "US"
      @letter.postage_type = "international_origin"
    end

    if @letter.save
      redirect_to @letter, notice: "Letter was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /letters/1
  def update
    authorize @letter

    if @letter.batch_id.present? && params[:letter][:postage_type].present?
      redirect_to @letter, alert: "Cannot change postage type for a letter that is part of a batch."
      return
    end

    # Set postage type to international_origin if return address is not US
    if params[:letter][:return_address_id].present?
      return_address = ReturnAddress.find(params[:letter][:return_address_id])
      if return_address.country != "US"
        params[:letter][:postage_type] = "international_origin"
      end
    end

    if @letter.update(letter_params)
      redirect_to @letter, notice: "Letter was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /letters/1
  def destroy
    authorize @letter
    @letter.destroy!
    redirect_to letters_path, status: :see_other, notice: "Letter was successfully destroyed."
  end

  # POST /letters/1/generate_label
  def generate_label
    authorize @letter, :generate_label?
    template = params[:template]
    include_qr_code = params[:qr].present?

    # Generate label with specified template
    begin
      # Let the model method handle saving itself
      if @letter.generate_label(template:, include_qr_code:)
        if @letter.label.attached?
          # Redirect back to the letter page with a success message
          redirect_to @letter, notice: "Label was successfully generated."
        else
          redirect_to @letter, alert: "Failed to generate label."
        end
      else
        redirect_to @letter, alert: "Failed to generate label: #{@letter.errors.full_messages.join(", ")}"
      end
    rescue => e
      raise
      redirect_to @letter, alert: "Error generating label: #{e.message}"
    end
  end

  def preview_template
    authorize @letter, :preview_template?
    template = params["template"]
    include_qr_code = params["qr"].present?
    send_data SnailMail::Service.generate_label(@letter, { template:, include_qr_code: }).render, type: "application/pdf", disposition: "inline"
  end

  # POST /letters/1/mark_printed
  def mark_printed
    authorize @letter, :mark_printed?
    if @letter.mark_printed!
      redirect_to @letter, notice: "Letter has been marked as printed."
    else
      redirect_to @letter, alert: "Could not mark letter as printed: #{@letter.errors.full_messages.join(", ")}"
    end
  end

  # POST /letters/1/mark_mailed
  def mark_mailed
    authorize @letter, :mark_mailed?
    if @letter.mark_mailed!
      User::UpdateTasksJob.perform_now(current_user)
      redirect_to @letter, notice: "Letter has been marked as mailed."
    else
      redirect_to @letter, alert: "Could not mark letter as mailed: #{@letter.errors.full_messages.join(", ")}"
    end
  end

  # POST /letters/1/mark_received
  def mark_received
    authorize @letter, :mark_received?
    if @letter.mark_received!
      redirect_to @letter, notice: "Letter has been marked as received."
    else
      redirect_to @letter, alert: "Could not mark letter as received: #{@letter.errors.full_messages.join(", ")}"
    end
  end

  # POST /letters/1/clear_label
  def clear_label
    authorize @letter, :clear_label?
    if @letter.pending? && @letter.label.attached?
      @letter.label.purge
      redirect_to @letter, notice: "Label has been cleared."
    else
      redirect_to @letter, alert: "Cannot clear label: Letter is not in pending state or has no label attached."
    end
  end

  # POST /letters/1/buy_indicia
  def buy_indicia
    authorize @letter, :buy_indicia?
    if @letter.batch_id.present?
      redirect_to @letter, alert: "Cannot buy indicia for a letter that is part of a batch."
      return
    end

    if @letter.postage_type != "indicia"
      redirect_to @letter, alert: "Letter must be set to indicia postage type first."
      return
    end

    if @letter.usps_indicium.present?
      redirect_to @letter, alert: "Indicia already purchased for this letter."
      return
    end

    payment_account = USPS::PaymentAccount.find_by(id: params[:usps_payment_account_id])
    if payment_account.nil?
      redirect_to @letter, alert: "Please select a valid payment account."
      return
    end

    indicium = USPS::Indicium.new(letter: @letter, payment_account: payment_account)
    begin
      indicium.buy!
      redirect_to @letter, notice: "Indicia purchased successfully."
    rescue => e
      redirect_to @letter, alert: "Failed to purchase indicia: #{e.message}"
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_letter
    @letter = Letter.find_by_public_id!(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def letter_params
    params.require(:letter).permit(
      :body,
      :height,
      :width,
      :weight,
      :non_machinable,
      :processing_category,
      :postage_type,
      :mailing_date,
      :rubber_stamps,
      :user_facing_title,
      :usps_mailer_id_id,
      :return_address_id,
      :return_address_name,
      :recipient_email,
      address_attributes: [
        :id,
        :first_name,
        :last_name,
        :line_1,
        :line_2,
        :city,
        :state,
        :postal_code,
        :country,
      ],
      return_address_attributes: [
        :id,
        :name,
        :line_1,
        :line_2,
        :city,
        :state,
        :postal_code,
        :country,
      ],
      tags: [],
    )
  end
end
