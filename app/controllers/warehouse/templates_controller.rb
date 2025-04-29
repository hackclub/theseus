class Warehouse::TemplatesController < ApplicationController
  before_action :set_warehouse_template, only: %i[ show edit update destroy ]

  # GET /warehouse/templates or /warehouse/templates.json
  def index
    authorize Warehouse::Template
    @warehouse_templates = Warehouse::Template.all
  end

  # GET /warehouse/templates/1 or /warehouse/templates/1.json
  def show
    authorize @warehouse_template
  end

  # GET /warehouse/templates/new
  def new
    authorize Warehouse::Template
    @warehouse_template = Warehouse::Template.new
  end

  # GET /warehouse/templates/1/edit
  def edit
    authorize @warehouse_template
  end

  # POST /warehouse/templates or /warehouse/templates.json
  def create
    @warehouse_template = Warehouse::Template.new(warehouse_template_params.merge(user: current_user, source_tag: SourceTag.web_tag))
    authorize @warehouse_template

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
    authorize @warehouse_template
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
    authorize @warehouse_template
    @warehouse_template.destroy!

    respond_to do |format|
      format.html { redirect_to warehouse_templates_path, status: :see_other, notice: "Template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse_template
      @warehouse_template = Warehouse::Template.find(params.require(:id))
    end

    # Only allow a list of trusted parameters through.
    def warehouse_template_params
      params.require(:warehouse_template).permit(
        :name, :public,
        line_items_attributes: [ :id, :sku_id, :quantity, :_destroy ]
      )
    end
end
