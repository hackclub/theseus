class LettersController < ApplicationController
  before_action :set_letter, except: %i[ index new create ]

  # GET /letters
  def index
    # Get all letters with their associations
    @all_letters = Letter.includes(:batch, :address, :usps_mailer_id, :label_attachment, :label_blob)
    
    # Get unbatched letters with pagination
    @unbatched_letters = @all_letters.not_in_batch.page(params[:page]).per(20)
    
    # Get batched letters grouped by batch
    @batched_letters = @all_letters.in_batch.group_by(&:batch)
  end

  # GET /letters/1
  def show
    @available_templates = SnailMail::Service.available_templates
  end

  # GET /letters/new
  def new
    @letter = Letter.new
    @letter.build_address
    # Don't build a return address by default - let the user select one
  end

  # GET /letters/1/edit
  def edit
    # If letter doesn't have a return address already, don't build one
    # Let the user select one from the dropdown
  end

  # POST /letters
  def create
    @letter = Letter.new(letter_params)

    if @letter.save
      redirect_to @letter, notice: "Letter was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /letters/1
  def update
    if @letter.update(letter_params)
      redirect_to @letter, notice: "Letter was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /letters/1
  def destroy
    @letter.destroy!
    redirect_to letters_path, status: :see_other, notice: "Letter was successfully destroyed."
  end

  # POST /letters/1/generate_label
  def generate_label
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
        redirect_to @letter, alert: "Failed to generate label: #{@letter.errors.full_messages.join(', ')}"
      end
    rescue => e
      raise
      redirect_to @letter, alert: "Error generating label: #{e.message}"
    end
  end

  def preview_template
    template = params['template']
    include_qr_code = params['qr'].present?
    send_data SnailMail::Service.generate_label(@letter, { template:, include_qr_code:  }).render, type: 'application/pdf', disposition: 'inline'
  end
  
  # POST /letters/1/mark_printed
  def mark_printed
    if @letter.mark_printed
      redirect_to @letter, notice: "Letter has been marked as printed."
    else
      redirect_to @letter, alert: "Could not mark letter as printed: #{@letter.errors.full_messages.join(', ')}"
    end
  end
  
  # POST /letters/1/mark_mailed
  def mark_mailed
    if @letter.mark_mailed
      redirect_to @letter, notice: "Letter has been marked as mailed."
    else
      redirect_to @letter, alert: "Could not mark letter as mailed: #{@letter.errors.full_messages.join(', ')}"
    end
  end
  
  # POST /letters/1/mark_received
  def mark_received
    if @letter.mark_received
      redirect_to @letter, notice: "Letter has been marked as received."
    else
      redirect_to @letter, alert: "Could not mark letter as received: #{@letter.errors.full_messages.join(', ')}"
    end
  end

  # POST /letters/1/clear_label
  def clear_label
    if @letter.pending? && @letter.label.attached?
      @letter.label.purge
      redirect_to @letter, notice: "Label has been cleared."
    else
      redirect_to @letter, alert: "Cannot clear label: Letter is not in pending state or has no label attached."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_letter
      @letter = Letter.find_by_hashid!(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def letter_params
      params.require(:letter).permit(
        :height,
        :width,
        :weight,
        :rubber_stamps,
        :usps_mailer_id_id,
        :return_address_id,
        address_attributes: [
          :first_name,
          :last_name,
          :line_1,
          :line_2,
          :city,
          :state,
          :postal_code,
          :country,
          :phone_number,
          :email
        ],
        return_address_attributes: [
          :name,
          :line_1,
          :line_2,
          :city,
          :state,
          :postal_code,
          :country,
          :shared,
          :user_id,
          :from_letter
        ]
      )
    end
end
