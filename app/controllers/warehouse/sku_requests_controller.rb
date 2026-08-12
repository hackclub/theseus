# frozen_string_literal: true

class Warehouse::SKURequestsController < ApplicationController
  before_action :set_sku_request, except: %i[index new create]

  def index
    authorize Warehouse::SKURequest
    @sku_requests = policy_scope(Warehouse::SKURequest).includes(:user, :warehouse_sku).order(created_at: :desc)
    render Views::Warehouse::SKURequests::Index.new(sku_requests: @sku_requests)
  end

  def show
    authorize @sku_request
    render Views::Warehouse::SKURequests::Show.new(sku_request: @sku_request)
  end

  def new
    authorize Warehouse::SKURequest
    @sku_request = Warehouse::SKURequest.new
    render Views::Warehouse::SKURequests::New.new(sku_request: @sku_request)
  end

  def create
    @sku_request = Warehouse::SKURequest.new(sku_request_params.merge(user: current_user))
    authorize @sku_request
    if @sku_request.save
      redirect_to warehouse_sku_request_path(@sku_request), notice: "SKU request created."
    else
      render Views::Warehouse::SKURequests::New.new(sku_request: @sku_request), status: :unprocessable_entity
    end
  end

  def edit
    authorize @sku_request
    render Views::Warehouse::SKURequests::Edit.new(sku_request: @sku_request)
  end

  def update
    authorize @sku_request
    if @sku_request.update(sku_request_params)
      redirect_to warehouse_sku_request_path(@sku_request), notice: "SKU request updated."
    else
      render Views::Warehouse::SKURequests::Edit.new(sku_request: @sku_request), status: :unprocessable_entity
    end
  end

  def submit
    authorize @sku_request
    @sku_request.submit!
    redirect_to warehouse_sku_request_path(@sku_request), flash: { success: "SKU request submitted for review." }
  end

  def approve
    authorize @sku_request
    @sku_request.assigned_sku_code = params[:assigned_sku_code]
    @sku_request.reviewed_by = current_user
    if @sku_request.assigned_sku_code.blank?
      redirect_to warehouse_sku_request_path(@sku_request), alert: "SKU code is required to approve."
      return
    end
    begin
      @sku_request.approve!
      redirect_to warehouse_sku_request_path(@sku_request), flash: { success: "SKU request approved! SKU created in Zenventory." }
    rescue => e
      redirect_to warehouse_sku_request_path(@sku_request), alert: "Approval failed: #{e.message}"
    end
  end

  def reject
    authorize @sku_request
    @sku_request.update!(reviewed_by: current_user, rejection_reason: params[:rejection_reason])
    @sku_request.reject!
    redirect_to warehouse_sku_request_path(@sku_request), flash: { success: "SKU request rejected." }
  end

  private

  def set_sku_request = @sku_request = Warehouse::SKURequest.find(params[:id])

  def sku_request_params
    params.require(:warehouse_sku_request).permit(
      :name, :description, :category, :unit_cost, :country_of_origin,
      :hs_code, :customs_description, :program, :expected_arrival,
      :expected_quantity, :suggested_sku_code, :image
    )
  end
end
