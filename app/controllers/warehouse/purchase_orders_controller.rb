# frozen_string_literal: true

class Warehouse::PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase_order, except: %i[new create index]

  def index
    authorize Warehouse::PurchaseOrder
    @purchase_orders = policy_scope(Warehouse::PurchaseOrder).includes(:user, :line_items).order(created_at: :desc)
  end

  def show
    authorize @purchase_order
  end

  def new
    authorize Warehouse::PurchaseOrder
    @purchase_order = Warehouse::PurchaseOrder.new
    @purchase_order.line_items.build
  end

  def create
    @purchase_order = Warehouse::PurchaseOrder.new(
      purchase_order_params.merge(user: current_user)
    )
    authorize @purchase_order

    if @purchase_order.save
      redirect_to warehouse_purchase_order_path(@purchase_order), notice: "Purchase order was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @purchase_order
  end

  def update
    authorize @purchase_order

    if @purchase_order.update(purchase_order_params)
      redirect_to warehouse_purchase_order_path(@purchase_order), notice: "Purchase order was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @purchase_order

    @purchase_order.destroy!
    redirect_to warehouse_purchase_orders_path, status: :see_other, notice: "Purchase order was deleted."
  end

  def submit_for_approval
    authorize @purchase_order, :submit?
    @purchase_order.submit_for_approval!
    Warehouse::CzarMailer.po_submitted(@purchase_order).deliver_later
    redirect_to warehouse_purchase_order_path(@purchase_order), flash: { success: "Purchase order submitted for approval." }
  end

  def approve
    authorize @purchase_order
    ActiveRecord::Base.transaction do
      @purchase_order.update!(reviewed_by: current_user)
      @purchase_order.approve!
    end
    Warehouse::CzarMailer.po_approved(@purchase_order).deliver_later
    redirect_to warehouse_purchase_order_path(@purchase_order), flash: { success: "Purchase order approved." }
  end

  def reject
    authorize @purchase_order, :return_for_revision?
    ActiveRecord::Base.transaction do
      @purchase_order.update!(reviewed_by: current_user, reviewer_notes: params[:reviewer_notes])
      @purchase_order.return_for_revision!
    end
    Warehouse::CzarMailer.po_returned(@purchase_order).deliver_later
    redirect_to warehouse_purchase_order_path(@purchase_order), flash: { success: "Purchase order returned for revision." }
  end

  def revise
    authorize @purchase_order
    @purchase_order.revise!
    redirect_to edit_warehouse_purchase_order_path(@purchase_order), flash: { success: "Purchase order returned to draft for revision." }
  end

  def send_to_zenventory
    authorize @purchase_order

    begin
      @purchase_order.dispatch!
    rescue Zenventory::ZenventoryError => e
      event_id = Sentry.capture_exception(e)&.event_id
      redirect_to warehouse_purchase_order_path(@purchase_order), alert: "Zenventory said \"#{e.message}\" (error: #{event_id})"
      return
    rescue AASM::InvalidTransition => e
      event_id = Sentry.capture_exception(e)&.event_id
      redirect_to warehouse_purchase_order_path(@purchase_order), alert: "Couldn't dispatch purchase order! Wrong state? (error: #{event_id})"
      return
    end

    redirect_to warehouse_purchase_order_path(@purchase_order), flash: { success: "Successfully sent to Zenventory!" }
  end

  def sync
    authorize @purchase_order

    begin
      @purchase_order.sync_from_zenventory!
    rescue Zenventory::ZenventoryError => e
      event_id = Sentry.capture_exception(e)&.event_id
      redirect_to warehouse_purchase_order_path(@purchase_order), alert: "Zenventory said \"#{e.message}\" (error: #{event_id})"
      return
    end

    redirect_to warehouse_purchase_order_path(@purchase_order), flash: { success: "Synced from Zenventory!" }
  end

  private

  def set_purchase_order
    @purchase_order = Warehouse::PurchaseOrder.find(params[:id])
  end

  def purchase_order_params
    params.require(:warehouse_purchase_order).permit(
      :supplier_name,
      :supplier_id,
      :notes,
      :required_by_date,
      line_items_attributes: %i[id sku_id sku_request_id quantity unit_cost _destroy]
    )
  end
end
