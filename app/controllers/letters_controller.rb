class LettersController < ApplicationController
  before_action :set_letter, only: %i[ show edit update destroy ]

  # GET /letters or /letters.json
  def index
    @letters = Letter.all
  end

  # GET /letters/1 or /letters/1.json
  def show
  end

  # GET /letters/new
  def new
    @letter = Letter.new
  end

  # GET /letters/1/edit
  def edit
  end

  # POST /letters or /letters.json
  def create
    @letter = Letter.new(letter_params)

    respond_to do |format|
      if @letter.save
        format.html { redirect_to @letter, notice: "Letter was successfully created." }
        format.json { render :show, status: :created, location: @letter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @letter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /letters/1 or /letters/1.json
  def update
    respond_to do |format|
      if @letter.update(letter_params)
        format.html { redirect_to @letter, notice: "Letter was successfully updated." }
        format.json { render :show, status: :ok, location: @letter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @letter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /letters/1 or /letters/1.json
  def destroy
    @letter.destroy!

    respond_to do |format|
      format.html { redirect_to letters_path, status: :see_other, notice: "Letter was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_letter
      @letter = Letter.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def letter_params
      params.fetch(:letter, {})
    end
end
