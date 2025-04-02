class LettersController < ApplicationController
  before_action :set_letter, except: %i[ index new create ]

  # GET /letters
  def index
    @batched_letters = Letter.in_batch
                             .includes(:batch, :address, :usps_mailer_id, :label_attachment, :label_blob)
                             .group_by(&:batch)
    @unbatched_letters = Letter.not_in_batch
                               .includes(:address, :usps_mailer_id, :label_attachment, :label_blob)
  end

  # GET /letters/1
  def show
    @available_templates = SnailMail::Service.available_templates
  end

  # GET /letters/new
  def new
    @letter = Letter.new
    @letter.build_address
    @letter.build_return_address
  end

  # GET /letters/1/edit
  def edit
    # If letter doesn't have a return address already, build one
    @letter.build_return_address unless @letter.return_address
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
    
    # Generate label with specified template
    begin
      # Let the model method handle saving itself
      if @letter.generate_label(template:)
        if @letter.label.attached?
          # Redirect to the label URL
          redirect_to rails_blob_path(@letter.label, disposition: 'inline')
        else
          redirect_to @letter, alert: "Failed to generate label."
        end
      else
        redirect_to @letter, alert: "Failed to generate label: #{@letter.errors.full_messages.join(', ')}"
      end
    rescue => e
      redirect_to @letter, alert: "Error generating label: #{e.message}"
    end
  end

  def preview_template
    template = params['template']
    include_qr_code = params['qr']
    send_data SnailMail::Service.generate_label(@letter, { template:, include_qr_code:  }).render, type: 'application/pdf', disposition: 'inline'
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
        :extra_data,
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
          :user_id
        ]
      )
    end
end
