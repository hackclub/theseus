class LettersToolbox < ApplicationToolbox
  default_param :letter_id, :string, "Letter ID (e.g. ltr!...)", except: [ :search, :create ]
  before_action :set_letter, except: [ :search, :create ]
  before_action :require_letter_owner!, only: [ :update, :generate_label, :mark_printed, :mark_mailed, :mark_received ]

  tool "Search physical letters by query, status, or both. Returns paginated list with address, postage, and state", access: :read do
    param :query, :string, "Full-text search across title, recipient, address", optional: true
    param :status, :string, "Filter by letter state (pending → printed → mailed → received)", optional: true, enum: %w[pending printed mailed received]
    param :page, :integer, "Page number", optional: true
  end
  def search
    scope = policy_scope(Letter).includes(:address, :return_address).where.not(aasm_state: "queued").order(created_at: :desc)
    scope = scope.search(params[:query]) if params[:query].present?
    scope = scope.where(aasm_state: params[:status]) if params[:status].present?
    @letters = paginate(scope)
  end

  tool "Show full detail for a physical letter including address, return address, postage, and tags", access: :read
  def show
    @letter = @letter # already set by before_action; load associations
    @letter.address
    @letter.return_address
  end

  tool "Create a new physical letter with recipient address and postage details", access: :write do
    param :body, :string, "Letter body text", optional: true
    param :height, :number, "Envelope height in inches", optional: true
    param :width, :number, "Envelope width in inches", optional: true
    param :weight, :number, "Weight in ounces", optional: true
    param :non_machinable, :boolean, "Letter requires hand-processing (can't go through USPS sorting machines)", optional: true
    param :processing_category, :string, "Mail class: letter (standard #10 envelope) or flat (large envelope)", enum: %w[letter flat]
    param :postage_type, :string, "Postage method: stamps (physical), indicia (USPS electronic postage), or international_origin", optional: true, enum: %w[stamps indicia international_origin]
    param :mailing_date, :string, "Mailing date (YYYY-MM-DD), required for indicia", optional: true
    param :rubber_stamps, :string, "Rubber stamp text", optional: true
    param :user_facing_title, :string, "Display title for the letter", optional: true
    param :return_address_id, :integer, "ID of the sender return address (use return_addresses_list to find)"
    param :recipient_email, :string, "Recipient email for tracking notifications", optional: true
    param :tags, [ :string ], "Tags for categorization", optional: true
    param :address, :object, "Recipient address" do
      param :first_name, :string, "First name"
      param :last_name, :string, "Last name", optional: true
      param :line_1, :string, "Address line 1"
      param :line_2, :string, "Address line 2", optional: true
      param :city, :string, "City"
      param :state, :string, "State/province"
      param :postal_code, :string, "Postal code"
      param :country, :string, "Country code (e.g. US, CA)", optional: true, default: "US"
    end
  end
  def create
    @letter = Letter.new(create_letter_params)
    @letter.user = current_user
    @letter.usps_mailer_id = current_user.home_mid

    # Auto-set postage type to international_origin if return address is not US
    if @letter.return_address&.country != "US"
      @letter.postage_type = "international_origin"
    end

    @letter.save!
    render :show
    suggests :generate_label, "Generate a PDF label for this letter"
  end

  tool "Update a pending physical letter's details", access: :write do
    param :body, :string, "Letter body text", optional: true
    param :height, :number, "Envelope height in inches", optional: true
    param :width, :number, "Envelope width in inches", optional: true
    param :weight, :number, "Weight in ounces", optional: true
    param :non_machinable, :boolean, "Letter requires hand-processing (can't go through USPS sorting machines)", optional: true
    param :processing_category, :string, "Mail class: letter (standard #10 envelope) or flat (large envelope)", optional: true, enum: %w[letter flat]
    param :postage_type, :string, "Postage method: stamps (physical), indicia (USPS electronic postage), or international_origin", optional: true, enum: %w[stamps indicia international_origin]
    param :mailing_date, :string, "Mailing date (YYYY-MM-DD)", optional: true
    param :rubber_stamps, :string, "Rubber stamp text", optional: true
    param :user_facing_title, :string, "Display title for the letter", optional: true
    param :return_address_id, :integer, "ID of the sender return address (use return_addresses_list to find)", optional: true
    param :recipient_email, :string, "Recipient email for tracking notifications", optional: true
    param :tags, [ :string ], "Tags for categorization", optional: true
    param :address, :object, "Recipient address (updates existing)", optional: true do
      param :first_name, :string, "First name", optional: true
      param :last_name, :string, "Last name", optional: true
      param :line_1, :string, "Address line 1", optional: true
      param :line_2, :string, "Address line 2", optional: true
      param :city, :string, "City", optional: true
      param :state, :string, "State/province", optional: true
      param :postal_code, :string, "Postal code", optional: true
      param :country, :string, "Country code (e.g. US, CA)", optional: true
    end
  end
  def update
    # Auto-set postage type if changing return address to non-US
    if params[:return_address_id].present?
      ra = ReturnAddress.find(params[:return_address_id])
      params[:postage_type] = "international_origin" if ra.country != "US"
    end

    @letter.update!(update_letter_params)
    render :show
  end

  tool "Generate a PDF mailing label for a letter. Check letter details with letters_show afterward", access: :write do
    param :template, :string, "Label template name", optional: true
    param :qr, :boolean, "Include QR code on label", optional: true
  end
  def generate_label
    @letter.generate_label(template: params[:template], include_qr_code: params[:qr].present?)

    if @letter.label.attached?
      render json: {
        letter_id: @letter.public_id,
        status: "label_generated",
        label_url: Rails.application.routes.url_helpers.rails_blob_path(@letter.label, only_path: true)
      }
    else
      render_error "Failed to generate label"
    end
  end

  tool "Mark a pending letter as printed (pending → printed)", access: :write
  def mark_printed
    @letter.mark_printed!
    render json: {
      letter_id: @letter.public_id,
      state: @letter.aasm_state,
      printed_at: @letter.printed_at&.iso8601
    }
  end

  tool "Mark a printed letter as mailed (printed → mailed)", access: :write
  def mark_mailed
    halt error: "Letter already mailed" if @letter.been_mailed?
    @letter.mark_mailed!
    render json: {
      letter_id: @letter.public_id,
      state: @letter.aasm_state,
      mailed_at: @letter.mailed_at&.iso8601
    }
  end

  tool "Mark a mailed letter as received by the recipient (mailed → received)", access: :write
  def mark_received
    @letter.mark_received!
    render json: {
      letter_id: @letter.public_id,
      state: @letter.aasm_state,
      received_at: @letter.received_at&.iso8601
    }
  end

  private

  def set_letter
    @letter = Letter.find_by_public_id!(params[:letter_id])
    halt error: "Couldn't find that letter" unless policy(@letter).show?
  end

  def require_letter_owner!
    halt error: "Only the letter owner or an admin can do that" unless @letter.user == current_user || admin?
  end

  def create_letter_params
    permitted = params.permit(
      :body, :height, :width, :weight, :non_machinable,
      :processing_category, :postage_type, :mailing_date,
      :rubber_stamps, :user_facing_title, :return_address_id,
      :recipient_email, tags: [],
    )

    if params[:address].present?
      permitted[:address_attributes] = params[:address].permit(
        :first_name, :last_name, :line_1, :line_2,
        :city, :state, :postal_code, :country,
      )
    end

    permitted
  end

  def update_letter_params
    permitted = params.permit(
      :body, :height, :width, :weight, :non_machinable,
      :processing_category, :postage_type, :mailing_date,
      :rubber_stamps, :user_facing_title, :return_address_id,
      :recipient_email, tags: [],
    )

    if params[:address].present?
      permitted[:address_attributes] = params[:address].permit(
        :first_name, :last_name, :line_1, :line_2,
        :city, :state, :postal_code, :country,
      )
      permitted[:address_attributes][:id] = @letter.address_id
    end

    permitted
  end
end
