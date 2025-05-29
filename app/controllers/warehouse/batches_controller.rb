class Warehouse::BatchesController < BaseBatchesController
  before_action :set_allowed_templates, only: %i[ new create ]

  # GET /warehouse/batches or /warehouse/batches.json
  def index
    authorize Warehouse::Batch
    @batches = policy_scope(Warehouse::Batch).order(created_at: :desc)
  end

  # GET /warehouse/batches/1 or /warehouse/batches/1.json
  def show
    authorize @batch
  end

  # GET /warehouse/batches/new
  def new
    authorize Warehouse::Batch
    @batch = Warehouse::Batch.new
  end

  # GET /warehouse/batches/1/edit
  def edit
    authorize @batch
  end

  # POST /warehouse/batches or /warehouse/batches.json
  def create
    authorize Warehouse::Batch
    @batch = Warehouse::Batch.new(batch_params.merge(user: current_user))

    if @batch.save
      @batch.aasm_state = :awaiting_field_mapping
      @batch.save!
      redirect_to map_fields_warehouse_batch_path(@batch), notice: "Please map your CSV fields to address fields."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /warehouse/batches/1 or /warehouse/batches/1.json
  def update
    authorize @batch
    if @batch.update(batch_params)
      # If template changed and batch hasn't been processed, recreate orders
      if @batch.may_mark_processed? && @batch.saved_change_to_warehouse_template_id?
        # Delete existing orders
        @batch.orders.destroy_all

        # Recreate orders from addresses with new template
        @batch.addresses.each do |address|
          Warehouse::Order.from_template(
            @batch.warehouse_template,
            batch: @batch,
            recipient_email: address.email,
            address: address,
            user: @batch.user,
            idempotency_key: "batch_#{@batch.id}_address_#{address.id}",
            user_facing_title: @batch.warehouse_user_facing_title,
            tags: @batch.tags,
          ).save!
        end
      end

      # Always update tags and user facing title on orders
      @batch.orders.update_all(
        tags: @batch.tags,
        user_facing_title: @batch.warehouse_user_facing_title,
      )

      redirect_to warehouse_batch_path(@batch), notice: "Batch was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @batch
    @batch.destroy
    redirect_to warehouse_batches_path, notice: "Batch was successfully destroyed."
  end

  def process_form
    authorize @batch, :process_form?
    render :process_warehouse
  end

  def process_batch
    authorize @batch, :process_batch?
    if @batch.process!
      redirect_to warehouse_batch_path(@batch), notice: "Batch was successfully processed."
    else
      render :process_form, status: :unprocessable_entity
    end
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
        Rails.logger.warn(e)
        uuid = Honeybadger.notify(e)
        redirect_to warehouse_batch_path(@batch), flash: { alert: "Error mapping fields! #{e.message} (please report EID: #{uuid})" }
        return
      end
      redirect_to process_confirm_warehouse_batch_path(@batch), notice: "Field mapping saved. Please review and process your batch."
    else
      flash.now[:error] = "Failed to save field mapping. #{@batch.errors.full_messages.join(", ")}"
      render :map_fields, status: :unprocessable_entity
    end
  end

  private

  def batch_params
    params.require(:batch).permit(:warehouse_template_id, :warehouse_user_facing_title, :csv, tags: [])
  end

  def set_allowed_templates
    @allowed_templates = Warehouse::Template.where(public: true).or(Warehouse::Template.where(user: current_user))
  end
end
