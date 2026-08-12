class Warehouse::SKUsController < ApplicationController
  before_action :set_warehouse_sku, only: %i[ show edit update sync_to_zenventory ]

  # GET /warehouse/skus or /warehouse/skus.json
  def index
    authorize Warehouse::SKU
    include_non_inventory = params[:include_non_inventory].present?
    warehouse_skus = include_non_inventory ? Warehouse::SKU.all : Warehouse::SKU.in_inventory
    view = params[:view] == 'flat' ? 'flat' : 'grouped'
    render Views::Warehouse::SKUs::Index.new(warehouse_skus:, include_non_inventory:, view:)
  end

  # GET /warehouse/skus/1 or /warehouse/skus/1.json
  def show
    authorize @warehouse_sku
    @recent_orders = Warehouse::Order.joins(:line_items)
      .where(warehouse_line_items: { sku_id: @warehouse_sku.id })
      .distinct.order(created_at: :desc).limit(10)
    outstanding_pos = Warehouse::PurchaseOrder.joins(:line_items)
      .where(warehouse_purchase_order_line_items: { sku_id: @warehouse_sku.id })
      .where.not(status: "completed")
      .distinct
    completed_pos = Warehouse::PurchaseOrder.joins(:line_items)
      .where(warehouse_purchase_order_line_items: { sku_id: @warehouse_sku.id })
      .where(status: "completed")
      .distinct.order(created_at: :desc).limit(10)
    @recent_purchase_orders = (outstanding_pos + completed_pos).sort_by(&:created_at).reverse
  end

  # GET /warehouse/skus/1/edit
  def edit
    authorize @warehouse_sku
  end

  # PATCH/PUT /warehouse/skus/1 or /warehouse/skus/1.json
  def update
    authorize @warehouse_sku
    respond_to do |format|
      if @warehouse_sku.update(warehouse_sku_params)
        format.html { redirect_to @warehouse_sku, notice: "WarehouseSKU was successfully updated." }
        format.json { render :show, status: :ok, location: @warehouse_sku }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @warehouse_sku.errors, status: :unprocessable_entity }
      end
    end
  end

  def sync_to_zenventory
    authorize @warehouse_sku
    @warehouse_sku.sync_to_zenventory!
    redirect_to @warehouse_sku, notice: "Synced to Zenventory."
  rescue Zenventory::ZenventoryError => e
    redirect_to @warehouse_sku, alert: "Zenventory sync failed: #{e.message}"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse_sku
      @warehouse_sku = Warehouse::SKU.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def warehouse_sku_params
      params.expect(warehouse_sku: [
        :sku, :name, :description, :unit_cost, :customs_description,
        :in_stock, :ai_enabled, :enabled, :category, :country_of_origin,
        :hs_code, :average_po_cost, :declared_unit_cost_override,
        :inbound, :zenventory_id
      ])
    end
end
