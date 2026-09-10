# frozen_string_literal: true

class Views::Letter::Batches::Map < Views::Batches::Map
  private

  def batch_path = letter_batch_path(@batch)
  def set_mapping_path = set_mapping_letter_batch_path(@batch)
  def submit_label = "✓ Map & Create Letters"
end
