class BaseBatchesController < ApplicationController
  before_action :set_batch, except: %i[ index new create ]
  before_action :setup_csv_fields, only: %i[ map_fields set_mapping ]

  REQUIRED_FIELDS = %w[first_name line_1 city state postal_code country].freeze
  PREVIEW_ROWS = 3

  # GET /batches or /batches.json
  def index
    authorize Batch
    @batches = policy_scope(Batch).order(created_at: :desc)
  end

  # GET /batches/1 or /batches/1.json
  def show
    authorize @batch
  end

  # GET /batches/1/edit
  def edit
    authorize @batch
  end

  # PATCH/PUT /batches/1 or /batches/1.json
  def update
    authorize @batch
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
    authorize @batch
    @batch.destroy!

    respond_to do |format|
      format.html { redirect_to batches_path, status: :see_other, notice: "Batch was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def map_fields
    authorize @batch, :map_fields?
  end

  def set_mapping
    authorize @batch, :set_mapping?
    mapping = mapping_params.to_h

    # Invert the mapping to get from CSV columns to address fields
    inverted_mapping = mapping.invert

    # Validate required fields
    missing_fields = REQUIRED_FIELDS.reject { |field| inverted_mapping[field].present? }

    if missing_fields.any?
      flash.now[:error] = "Please map the following required fields: #{missing_fields.join(", ")}"
      render :map_fields, status: :unprocessable_entity
      return
    end

    if @batch.update!(field_mapping: inverted_mapping)
      begin
        @batch.run_map!
      rescue StandardError => e
        raise
        Rails.logger.warn(e)
        uuid = Honeybadger.notify(e)
        redirect_to send("#{@batch.class.name.split("::").first.downcase}_batch_path", @batch), flash: { alert: "error mapping fields! #{e.message} (please report EID: #{uuid})" }
        return
      end
      redirect_to send("process_confirm_#{@batch.class.name.split("::").first.downcase}_batch_path", @batch), notice: "Field mapping saved. Please review and process your batch."
    else
      flash.now[:error] = "failed to save field mapping. #{@batch.errors.full_messages.join(", ")}"
      render :map_fields, status: :unprocessable_entity
    end
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  end

  def setup_csv_fields
    csv_rows = CSV.parse(@batch.csv_data)
    @csv_headers = csv_rows.first
    @csv_preview = csv_rows[1..PREVIEW_ROWS] || []

    # Get fields based on batch type
    @address_fields = if @batch.is_a?(Letter::Batch)
        # For letter batches, include address fields and rubber_stamps
        (Address.column_names - ["id", "created_at", "updated_at", "batch_id"]) +
          ["rubber_stamps"]
      else
        # For other batches, just include address fields
        (Address.column_names - ["id", "created_at", "updated_at"])
      end
  end

  def mapping_params
    params.require(:mapping).permit!
  end
end
