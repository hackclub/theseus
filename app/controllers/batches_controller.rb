class BatchesController < ApplicationController
  before_action :set_batch, only: %i[ show edit update destroy map_fields process_mapping ]
  before_action :setup_csv_fields, only: %i[ map_fields process_mapping ]

  REQUIRED_FIELDS = %w[first_name last_name line_1 city state postal_code country].freeze
  PREVIEW_ROWS = 3

  # GET /batches or /batches.json
  def index
    @batches = Batch.all
  end

  # GET /batches/1 or /batches/1.json
  def show
  end

  # GET /batches/new
  def new
    @batch = Batch.new
  end

  # GET /batches/1/edit
  def edit
  end

  # POST /batches or /batches.json
  def create
    @batch = Batch.new(
      batch_params.merge(user: current_user)
    )

    respond_to do |format|
      if @batch.save
        format.html { redirect_to map_fields_batch_path(@batch), notice: "Please map your CSV fields to address fields." }
        format.json { render :show, status: :created, location: @batch }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @batch.errors, status: :unprocessable_entity }
      end
    end
  end

  def map_fields
  end

  def process_mapping
    mapping = mapping_params.to_h
    
    # Validate required fields
    missing_fields = REQUIRED_FIELDS.reject { |field| mapping[field].present? }
    
    if missing_fields.any?
      flash.now[:error] = "Please map the following required fields: #{missing_fields.join(', ')}"
      render :map_fields, status: :unprocessable_entity
      return
    end

    if @batch.update(field_mapping: mapping)
      redirect_to @batch, notice: "Field mapping saved successfully."
    else
      flash.now[:error] = "Failed to save field mapping."
      render :map_fields, status: :unprocessable_entity
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
      require 'csv'
      
      csv_content = @batch.csv.download
      csv_rows = CSV.parse(csv_content)
      @csv_headers = csv_rows.first
      @csv_preview = csv_rows[1..PREVIEW_ROWS] || []
      @address_fields = (Address.column_names - ['id', 'created_at', 'updated_at']) + ['email']
    end

    # Only allow a list of trusted parameters through.
    def batch_params
      params.require(:batch).permit(:csv)
    end

    def mapping_params
      params.require(:mapping).permit(@address_fields)
    end
end
