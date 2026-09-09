class Warehouse::BatchesController < BaseBatchesController
  before_action :set_allowed_templates, only: %i[ new create edit ]

  # GET /warehouse/batches
  def index
    authorize Warehouse::Batch
    all_batches = policy_scope(Warehouse::Batch).order(created_at: :desc)
    batches = all_batches
    batches = batches.where(user_id: params[:user_id]) if params[:user_id].present? && current_user&.is_admin?
    batches = batches.search(params[:search]) if params[:search].present?
    users = current_user&.is_admin? ? User.where(id: all_batches.reorder(nil).select(:user_id).distinct).order(:email) : []
    render Views::Warehouse::Batches::Index.new(
      batches: batches,
      search: params[:search],
      user_id: params[:user_id],
      users: users
    )
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
    authorize @batch
    @batch.destroy
    redirect_to warehouse_batches_path, notice: "Batch was successfully destroyed."
  end

  def process_form
    authorize @batch, :process_form?
    @batch.preflight
    render Views::Warehouse::Batches::Process.new(batch: @batch)
  end

  def process_batch
    authorize @batch, :process_batch?
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
      render :process_warehouse, status: :unprocessable_entity
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
        skipped_countries = @batch.run_map!
      rescue StandardError => e
        Rails.logger.warn(e)
        event_id = Sentry.capture_exception(e)&.event_id
        redirect_to warehouse_batch_path(@batch), flash: { alert: "Error mapping fields! #{e.message} (error: #{event_id})" }
        return
      end
      notice = "Field mapping saved. Please review and process your batch."
      if skipped_countries.present?
        names = skipped_countries.map { |cc| ISO3166::Country[cc]&.common_name || cc }.to_sentence
        notice += " Addresses in #{names} were skipped — USPS does not currently deliver there."
      end
      redirect_to process_confirm_warehouse_batch_path(@batch), notice: notice
    else
      flash.now[:error] = "Failed to save field mapping. #{@batch.errors.full_messages.join(", ")}"
      render :map_fields, status: :unprocessable_entity
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
