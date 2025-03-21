class Warehouse::TemplatesController < ApplicationController
  before_action :set_warehouse_template, only: %i[ show edit update destroy ]

  # GET /warehouse/templates or /warehouse/templates.json
  def index
    @warehouse_templates = Warehouse::Template.all
  end

  # GET /warehouse/templates/1 or /warehouse/templates/1.json
  def show
  end

  # GET /warehouse/templates/new
  def new
    @warehouse_template = Warehouse::Template.new
  end

  # GET /warehouse/templates/1/edit
  def edit
  end

  # POST /warehouse/templates or /warehouse/templates.json
  def create
    @warehouse_template = Warehouse::Template.new(warehouse_template_params)

    respond_to do |format|
      if @warehouse_template.save
        format.html { redirect_to @warehouse_template, notice: "Template was successfully created." }
        format.json { render :show, status: :created, location: @warehouse_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @warehouse_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /warehouse/templates/1 or /warehouse/templates/1.json
  def update
    respond_to do |format|
      if @warehouse_template.update(warehouse_template_params)
        format.html { redirect_to @warehouse_template, notice: "Template was successfully updated." }
        format.json { render :show, status: :ok, location: @warehouse_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @warehouse_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /warehouse/templates/1 or /warehouse/templates/1.json
  def destroy
    @warehouse_template.destroy!

    respond_to do |format|
      format.html { redirect_to warehouse_templates_path, status: :see_other, notice: "Template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse_template
      @warehouse_template = Warehouse::Template.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def warehouse_template_params
      params.expect(warehouse_template: [ :name, line_items_attributes: [:sku_id, :quantity, :_destroy] ])
    end
end
