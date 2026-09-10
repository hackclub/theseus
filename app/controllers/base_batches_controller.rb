class BaseBatchesController < ApplicationController
  before_action :set_batch, except: %i[ index new create ]
  before_action :ensure_importable, only: %i[ set_mapping import_with_skip ]

  rescue_from BatchImporter::Error, with: :importer_refused

  private

  def set_batch
    @batch = batch_scope.find(params[:id])
  end

  # Importing twice appends a second copy of every row: duplicate letters, or
  # warehouse orders that ship and charge labor again. The mapping page is only
  # good for a batch that hasn't been imported yet.
  def ensure_importable
    return if @batch.awaiting_field_mapping?

    redirect_to batch_show_path, alert: "This batch has already been imported."
  end

  def importer_refused(error)
    redirect_to batch_map_fields_path, alert: error.message
  end

  # Both subclasses live in their own route namespace; the shared guards and
  # rescues need somewhere to send people back to.
  def batch_route_scope = @batch.is_a?(Letter::Batch) ? "letter" : "warehouse"
  def batch_show_path = send("#{batch_route_scope}_batch_path", @batch)
  def batch_map_fields_path = send("map_fields_#{batch_route_scope}_batch_path", @batch)
  def batch_new_path = send("new_#{batch_route_scope}_batch_path")

  # Letter and warehouse batches answer to different policies, so each
  # controller says which scope a member action may load from.
  def batch_scope = raise(NotImplementedError)
end
