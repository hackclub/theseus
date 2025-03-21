class Warehouse::SKUsController < ApplicationController
  before_action :set_warehouse_sku, only: %i[ show edit update ]

  # GET /warehouse/skus or /warehouse/skus.json
  def index
    authorize Warehouse::SKU
    @warehouse_skus = params[:include_non_inventory] ? Warehouse::SKU.all : Warehouse::SKU.in_inventory
  end

  # GET /warehouse/skus/1 or /warehouse/skus/1.json
  def show
    authorize @warehouse_sku
  end

  # GET /warehouse/skus/new
  def new
    authorize Warehouse::SKU
    @warehouse_sku = Warehouse::SKU.new
  end

  # GET /warehouse/skus/1/edit
  def edit
    authorize @warehouse_sku
  end

  # POST /warehouse/skus or /warehouse/skus.json
  def create
    @warehouse_sku = Warehouse::SKU.new(warehouse_sku_params)

    authorize @warehouse_sku

    respond_to do |format|
      if @warehouse_sku.save
        format.html { redirect_to @warehouse_sku, notice: "WarehouseSKU was successfully created." }
        format.json { render :show, status: :created, location: @warehouse_sku }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @warehouse_sku.errors, status: :unprocessable_entity }
      end
    end
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


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse_sku
      @warehouse_sku = Warehouse::SKU.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def warehouse_sku_params
      params.expect(warehouse_sku: [ :sku, :description, :unit_cost, :customs_description, :in_stock, :ai_enabled, :enabled ])
    end
end
