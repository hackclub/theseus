class BatchesController < ApplicationController
  before_action :set_batch, except: %i[ index new create ]
  before_action :set_allowed_templates, only: %i[ new create ]
  before_action :setup_csv_fields, only: %i[ map_fields set_mapping ]

  REQUIRED_FIELDS = %w[first_name line_1 city state postal_code country].freeze
  PREVIEW_ROWS = 3

  BATCH_TYPES = [
    ['Warehouse', 'Warehouse::Batch'],
    ['Letter', 'Letter::Batch']
  ].freeze

  # GET /batches or /batches.json
  def index
    @batches = Batch.all.order(created_at: :desc)
  end

  # GET /batches/1 or /batches/1.json
  def show
  end

  # GET /batches/new
  def new
    @batch_types = BATCH_TYPES
  end

  # GET /batches/1/edit
  def edit
  end

  # POST /batches or /batches.json
  def create
    @batch_types = BATCH_TYPES
    batch_type = batch_params[:type]
    
    # Validate that the type is one of our allowed types
    unless BATCH_TYPES.map(&:last).include?(batch_type)
      @batch = Batch.new(batch_params.merge(user: current_user))
      @batch.errors.add(:type, "must be one of: #{BATCH_TYPES.map(&:last).join(', ')}")
      render :new, status: :unprocessable_entity
      return
    end

    @batch = batch_type.constantize.new(batch_params.merge(user: current_user))

    if @batch.save!
      redirect_to map_fields_batch_path(@batch), notice: "Please map your CSV fields to address fields."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def map_fields
  end

  def set_mapping
    mapping = mapping_params.to_h
    
    # Invert the mapping to get from CSV columns to address fields
    inverted_mapping = mapping.invert
    
    # Validate required fields
    missing_fields = REQUIRED_FIELDS.reject { |field| inverted_mapping[field].present? }
    
    if missing_fields.any?
      flash.now[:error] = "Please map the following required fields: #{missing_fields.join(', ')}"
      render :map_fields, status: :unprocessable_entity
      return
    end

    if @batch.update(field_mapping: inverted_mapping)
      begin
        @batch.run_map!
      rescue StandardError => e
        Rails.logger.warn(e)
        redirect_to @batch, flash: { alert: "error mapping fields! #{e.message}" }
        return
      end
      redirect_to @batch, notice: "mapped! send it?"
    else
      flash.now[:error] = "failed to save field mapping. #{@batch.errors.full_messages.join(', ')}"
      render :map_fields, status: :unprocessable_entity
    end
  end

  def process_form
    case @batch.type
    when "Warehouse::Batch"
      render :process_warehouse
    when "Letter::Batch"
      render :process_letter
    end
  end

  def process_batch
    if @batch.warehouse_template.nil? && @batch.is_a?(Warehouse::Batch)
      redirect_to process_form_batch_path(@batch), alert: "Please select a warehouse template before processing."
      return
    end

    if @batch.process!
      redirect_to @batch, notice: " Batch processed successfully."
    else
      redirect_to @batch, error: "Failed to process batch."
    end
  end

  # PATCH/PUT /batches/1 or /batches/1.json
  def update
    respond_to do |format|
      if @batch.update(batch_params)
        format.html { redirect_to @batch, notice: "Batch was successfully updated." }
        format.json { render :show, status: :ok, location: @batch }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @batch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /batches/1 or /batches/1.json
  def destroy
    @batch.destroy!

    respond_to do |format|
      format.html { redirect_to batches_path, status: :see_other, notice: "Batch was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_batch
      @batch = Batch.find(params[:id])
    end

    def setup_csv_fields
      csv_content = @batch.csv.download
      csv_rows = CSV.parse(csv_content)
      @csv_headers = csv_rows.first
      @csv_preview = csv_rows[1..PREVIEW_ROWS] || []
      
      # Get fields based on batch type
      @address_fields = if @batch.is_a?(Letter::Batch)
        # For letter batches, include address fields and extra_data
        (Address.column_names - ['id', 'created_at', 'updated_at', 'batch_id']) +
        ['extra_data']
      else
        # For other batches, just include address fields
        (Address.column_names - ['id', 'created_at', 'updated_at'])
      end
    end

    # Only allow a list of trusted parameters through.
    def batch_params
      params.require(:batch).permit(
        :csv, 
        :warehouse_template_id, 
        :type, 
        :warehouse_purpose_code_id, 
        :warehouse_user_facing_title,
        :letter_height,
        :letter_width,
        :letter_weight
      )
    end

    def mapping_params
      params.require(:mapping).permit(@csv_headers)
    end
    def set_allowed_templates
      @allowed_templates = Warehouse::Template.where(public: true).or(Warehouse::Template.where(user: current_user))
    end
end
