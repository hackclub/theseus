class BaseBatchesController < ApplicationController
  before_action :set_batch, except: %i[ index new create ]

  private

  def set_batch
    @batch = batch_scope.find(params[:id])
  end

  # Letter and warehouse batches answer to different policies, so each
  # controller says which scope a member action may load from.
  def batch_scope = raise(NotImplementedError)
end
