class BaseBatchesController < ApplicationController
  before_action :set_batch, except: %i[ index new create ]

  # GET /batches/1 or /batches/1.json
  def show
    authorize @batch
  end

  # GET /batches/1/edit
  def edit
    authorize @batch
  end

  # PATCH/PUT /batches/1 or /batches/1.json
  def update
    authorize @batch
    respond_to do |format|
      if @batch.update(batch_params)
        format.html { redirect_to @batch, notice: "Batch was successfully updated." }
        format.json { render :show, status: :ok, location: @batch }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @batch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /batches/1 or /batches/1.json
  def destroy
    authorize @batch
    @batch.destroy!

    respond_to do |format|
      format.html { redirect_to batches_path, status: :see_other, notice: "Batch was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  end
end
