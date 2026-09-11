class Warehouse::BatchesController < BaseBatchesController
  before_action :set_allowed_templates, only: %i[ new create edit update ]
  before_action :ensure_processable, only: %i[ process_form process_batch ]

  # GET /warehouse/batches
  def index
    authorize Warehouse::Batch, policy_class: Warehouse::BatchPolicy
    all_batches = policy_scope(Warehouse::Batch, policy_scope_class: Warehouse::BatchPolicy::Scope).order(created_at: :desc)
    batches = all_batches
    batches = batches.where(user_id: params[:user_id]) if params[:user_id].present? && current_user&.is_admin?
    batches = batches.search(params[:search]) if params[:search].present?
    users = current_user&.is_admin? ? User.where(id: all_batches.reorder(nil).select(:user_id).distinct).order(:email) : []
    render Views::Warehouse::Batches::Index.new(
      batches: batches,
      search: params[:search],
      status: params[:status],
      user_id: params[:user_id],
      users: users
    )
  end

  # GET /warehouse/batches/1
  def show
    authorize @batch, policy_class: Warehouse::BatchPolicy
    render Views::Warehouse::Batches::Show.new(batch: @batch)
  end

  # GET /warehouse/batches/new
  def new
    authorize Warehouse::Batch, policy_class: Warehouse::BatchPolicy
    @batch = Warehouse::Batch.new
    render Views::Warehouse::Batches::New.new(batch: @batch, allowed_templates: @allowed_templates)
  end

  # GET /warehouse/batches/1/edit
  def edit
    authorize @batch, policy_class: Warehouse::BatchPolicy
    render Views::Warehouse::Batches::Edit.new(batch: @batch, allowed_templates: @allowed_templates)
  end

  # POST /warehouse/batches
  def create
    authorize Warehouse::Batch, policy_class: Warehouse::BatchPolicy
    @batch = Warehouse::Batch.new(batch_params.merge(user: current_user))

    if @batch.save
      redirect_to map_fields_warehouse_batch_path(@batch)
    else
      render Views::Warehouse::Batches::New.new(batch: @batch, allowed_templates: @allowed_templates), status: :unprocessable_entity
    end
  end

  # GET /warehouse/batches/:id/map
  def map_fields
    authorize @batch, policy_class: Warehouse::BatchPolicy
    render Views::Warehouse::Batches::Map.new(batch: @batch, csv_headers: @batch.csv_headers, sample_row: @batch.csv_sample_row)
  end

  # POST /warehouse/batches/:id/set_mapping
  def set_mapping
    authorize @batch, policy_class: Warehouse::BatchPolicy
    fields = Views::Batches::Map::ADDRESS_FIELDS.map(&:first)
    mapping = @batch.csv_headers.index_with { |header| params.dig(:field_mapping, header).to_s }
                    .select { |_, field| field.present? && field.in?(fields) }
    @batch.update!(field_mapping: mapping)
    importer = WarehouseBatchImporter.new(@batch)
    validation = importer.validate

    if validation.any? { |r| r[:status] == :error }
      render Views::Warehouse::Batches::Validate.new(batch: @batch, validation: validation)
    else
      count = importer.call
      redirect_to process_confirm_warehouse_batch_path(@batch), notice: "Imported #{count} addresses."
    end
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to map_fields_warehouse_batch_path(@batch), alert: "Mapping failed: #{e.message}"
  end

  # POST /warehouse/batches/:id/import_with_skip
  def import_with_skip
    authorize @batch, :update?, policy_class: Warehouse::BatchPolicy
    count = WarehouseBatchImporter.new(@batch).call(skip_invalid: true)
    redirect_to process_confirm_warehouse_batch_path(@batch), notice: "Imported #{count} addresses (skipped invalid rows)."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to map_fields_warehouse_batch_path(@batch), alert: "Import failed: #{e.message}"
  end

  # PATCH/PUT /warehouse/batches/1 or /warehouse/batches/1.json
  def update
    authorize @batch, policy_class: Warehouse::BatchPolicy
    if @batch.update(batch_params)
      # If template changed and batch hasn't been processed, recreate orders
      if (@batch.fields_mapped? || @batch.failed?) && @batch.saved_change_to_warehouse_template_id?
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
            billing_profile: @batch.billing_profile,
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
    authorize @batch, policy_class: Warehouse::BatchPolicy

    if @batch.destroy
      redirect_to warehouse_batches_path, status: :see_other, notice: "Batch was successfully destroyed."
    else
      redirect_to warehouse_batch_path(@batch), status: :see_other, alert: @batch.errors.full_messages.to_sentence.presence || "Batch could not be destroyed."
    end
  end

  def process_form
    authorize @batch, :process_form?, policy_class: Warehouse::BatchPolicy
    @batch.preflight
    render Views::Warehouse::Batches::Process.new(batch: @batch)
  end

  def process_batch
    authorize @batch, :process_batch?, policy_class: Warehouse::BatchPolicy
    profile_id = params.dig(:batch, :hcb_payment_account_id)
    if profile_id.present?
      profile = @batch.user.billing_profiles.find_by(id: profile_id)
      unless profile
        redirect_to process_confirm_warehouse_batch_path(@batch), alert: "Billing profile not found or doesn't belong to the batch owner."
        return
      end
      @batch.update!(billing_profile: profile)
    end
    if @batch.process!
      redirect_to warehouse_batch_path(@batch), notice: "Batch was successfully processed."
    else
      render Views::Warehouse::Batches::Process.new(batch: @batch), status: :unprocessable_entity
    end
  end

  private

  def batch_params
    permitted = params.require(:batch).permit(:warehouse_template_id, :warehouse_user_facing_title, :csv, tags: [])
    permitted.delete(:warehouse_template_id) if @batch && !(@batch.fields_mapped? || @batch.failed?)
    if permitted[:warehouse_template_id].present? && !@allowed_templates.exists?(id: permitted[:warehouse_template_id])
      permitted.delete(:warehouse_template_id)
    end
    permitted
  end

  def ensure_processable
    return if @batch.fields_mapped?

    alert = if @batch.processed?
      "This batch has already been processed."
    elsif @batch.awaiting_field_mapping?
      "Map this batch's CSV fields before processing it."
    else
      "This batch is already being processed."
    end
    redirect_to warehouse_batch_path(@batch), alert: alert
  end

  def set_allowed_templates
    @allowed_templates = Warehouse::Template.where(public: true).or(Warehouse::Template.where(user: current_user))
  end

  def batch_scope = policy_scope(Warehouse::Batch, policy_scope_class: Warehouse::BatchPolicy::Scope)
end
