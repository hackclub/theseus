# frozen_string_literal: true

class Views::Warehouse::Batches::Validate < Views::Batches::Validate
  private

  def batch_path = warehouse_batch_path(@batch)
  def import_path = import_with_skip_warehouse_batch_path(@batch)
  def new_path = new_warehouse_batch_path
end
