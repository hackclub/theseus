class SourceTagsController < ApplicationController
  before_action :set_source_tag, only: %i[ show edit update destroy ]

  # GET /source_tags or /source_tags.json
  def index
    @source_tags = SourceTag.all
  end

  # GET /source_tags/1 or /source_tags/1.json
  def show
  end

  # GET /source_tags/new
  def new
    @source_tag = SourceTag.new
  end

  # GET /source_tags/1/edit
  def edit
  end

  # POST /source_tags or /source_tags.json
  def create
    @source_tag = SourceTag.new(source_tag_params)

    respond_to do |format|
      if @source_tag.save
        format.html { redirect_to @source_tag, notice: "Source tag was successfully created." }
        format.json { render :show, status: :created, location: @source_tag }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @source_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /source_tags/1 or /source_tags/1.json
  def update
    respond_to do |format|
      if @source_tag.update(source_tag_params)
        format.html { redirect_to @source_tag, notice: "Source tag was successfully updated." }
        format.json { render :show, status: :ok, location: @source_tag }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @source_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /source_tags/1 or /source_tags/1.json
  def destroy
    @source_tag.destroy!

    respond_to do |format|
      format.html { redirect_to source_tags_path, status: :see_other, notice: "Source tag was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_source_tag
      @source_tag = SourceTag.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def source_tag_params
      params.expect(source_tag: [ :slug, :name, :owner ])
    end
end
