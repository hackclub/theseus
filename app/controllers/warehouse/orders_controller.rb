class Warehouse::OrdersController < ApplicationController
  before_action :set_warehouse_order, except: [:new, :create, :index]
  # GET /warehouse/orders or /warehouse/orders.json
  def index
    authorize Warehouse::Order

    # Get all orders with their associations using policy scope
    @all_orders = policy_scope(Warehouse::Order).includes(:batch, :address, :source_tag, :user)

    # Filter by batched/unbatched based on view parameter
    if params[:view] == "batched"
      @warehouse_orders = @all_orders.in_batch
    else
      @warehouse_orders = @all_orders.not_in_batch.page(params[:page]).per(20)
    end
  end

  # GET /warehouse/orders/1 or /warehouse/orders/1.json
  def show
    authorize @warehouse_order
  end

  # GET /warehouse/orders/new
  def new
    authorize Warehouse::Order
    @warehouse_order = Warehouse::Order.new
    @warehouse_order.build_address
  end

  # GET /warehouse/orders/1/edit
  def edit
    authorize @warehouse_order
  end

  def send_to_warehouse
    authorize @warehouse_order

    begin
      @warehouse_order.dispatch!
    rescue Zenventory::ZenventoryError => e
      uuid = Honeybadger.notify(e)
      redirect_to @warehouse_order, alert: "zenventory said \"#{e.message}\" (please report EID: #{uuid})"
    rescue AASM::InvalidTransition => e
      uuid = Honeybadger.notify(e)
      redirect_to @warehouse_order, alert: "couldn't dispatch order! wrong state? (please report EID: #{uuid})"
    end
    redirect_to @warehouse_order, flash: { success: "successfully sent to warehouse!" }
  end

  # POST /warehouse/orders or /warehouse/orders.json
  def create
    @warehouse_order = Warehouse::Order.new(
      warehouse_order_params.merge(
        user: current_user,
        source_tag: SourceTag.web_tag,
      )
    )

    authorize @warehouse_order

    respond_to do |format|
      if @warehouse_order.save
        format.html { redirect_to @warehouse_order, notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @warehouse_order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @warehouse_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /warehouse/orders/1 or /warehouse/orders/1.json
  def update
    authorize @warehouse_order
    respond_to do |format|
      if @warehouse_order.update(warehouse_order_params)
        format.html { redirect_to @warehouse_order, notice: "Order was successfully updated." }
        format.json { render :show, status: :ok, location: @warehouse_order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @warehouse_order.errors, status: :unprocessable_entity }
      end
    end
  end

  def cancel
    authorize @warehouse_order
    unless @warehouse_order.may_mark_canceled?
      redirect_back_or_to @warehouse_order, alert: "order is not in a cancelable state!"
    end
  end

  def confirm_cancel
    authorize @warehouse_order, :cancel?

    reason = params.require(:cancellation_reason)
    begin
      @warehouse_order.cancel!(reason)
    rescue Zenventory::ZenventoryError => e
      redirect_to @warehouse_order, alert: "couldn't cancel order! zenventory said: #{e.message}"
    rescue AASM::InvalidTransition => e
      redirect_to @warehouse_order, alert: "couldn't cancel order! wrong state?"
    end
  end

  # # DELETE /warehouse/orders/1 or /warehouse/orders/1.json
  def destroy
    authorize @warehouse_order
    @warehouse_order.destroy!

    respond_to do |format|
      format.html { redirect_to warehouse_orders_path, status: :see_other, notice: "it's gone." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_warehouse_order
    @warehouse_order = Warehouse::Order.find_by!(hc_id: params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def warehouse_order_params
    params.require(:warehouse_order).permit(
      :user_facing_title,
      :user_facing_description,
      :internal_notes,
      :recipient_email,
      :notify_on_dispatch,
      tags: [],
      line_items_attributes: [:id, :sku_id, :quantity, :_destroy],
      address_attributes: %i[first_name last_name line_1 line_2 city state postal_code country phone_number email],
    ).compact_blank
  end
end
