# frozen_string_literal: true

class Views::Letter::Batches::Validate < Views::Batches::Validate
  private

  def batch_path = letter_batch_path(@batch)
  def import_path = import_with_skip_letter_batch_path(@batch)
  def new_path = new_letter_batch_path
end
