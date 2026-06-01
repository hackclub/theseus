class Warehouse::BatchesController < BaseBatchesController
  before_action :set_allowed_templates, only: %i[ new create edit ]

  # GET /warehouse/batches
  def index
    authorize Warehouse::Batch
    @batches = policy_scope(Warehouse::Batch).order(created_at: :desc)
    render Views::Warehouse::Batches::Index.new(batches: @batches)
  end

  # GET /warehouse/batches/1
  def show
    authorize @batch
    render Views::Warehouse::Batches::Show.new(batch: @batch)
  end

  # GET /warehouse/batches/new
  def new
    authorize Warehouse::Batch
    @batch = Warehouse::Batch.new
    render Views::Warehouse::Batches::New.new(batch: @batch, allowed_templates: @allowed_templates)
  end

  # GET /warehouse/batches/1/edit
  def edit
    authorize @batch
    render Views::Warehouse::Batches::Edit.new(batch: @batch, allowed_templates: @allowed_templates)
  end

  # POST /warehouse/batches
  def create
    authorize Warehouse::Batch
    @batch = Warehouse::Batch.new(batch_params.merge(user: current_user))

    if @batch.save
      begin
        addresses_data = JSON.parse(params[:batch][:addresses_data])
        @batch.import_addresses!(addresses_data)
        redirect_to process_confirm_warehouse_batch_path(@batch), notice: "Batch created with #{@batch.addresses.count} addresses. Review and process."
      rescue StandardError => e
        event_id = Sentry.capture_exception(e)&.event_id
        redirect_to warehouse_batch_path(@batch), flash: { alert: "Batch created but address import failed: #{e.message} (error: #{event_id})" }
      end
    else
      render Views::Warehouse::Batches::New.new(batch: @batch, allowed_templates: @allowed_templates), status: :unprocessable_entity
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
      render Views::Warehouse::Batches::Edit.new(batch: @batch, allowed_templates: @allowed_templates), status: :unprocessable_entity
    end
  end

  def destroy
    authorize @batch
    @batch.destroy
    redirect_to warehouse_batches_path, notice: "Batch was successfully destroyed."
  end

  def process_form
    authorize @batch, :process_form?
    render Views::Warehouse::Batches::Process.new(batch: @batch)
  end

  def process_batch
    authorize @batch, :process_batch?
    if @batch.process!
      redirect_to warehouse_batch_path(@batch), notice: "Batch was successfully processed."
    else
      render :process_form, status: :unprocessable_entity
    end
  end

  private

  def batch_params
    params.require(:batch).permit(:warehouse_template_id, :warehouse_user_facing_title, :csv, :addresses_data, tags: [])
  end

  def set_allowed_templates
    @allowed_templates = Warehouse::Template.where(public: true).or(Warehouse::Template.where(user: current_user))
  end
end
