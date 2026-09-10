# frozen_string_literal: true

class LetterBatchImporter < BatchImporter
  private

  def import_row(row, address)
    @batch.letters.create!(
      address: address,
      height: @batch.letter_height,
      width: @batch.letter_width,
      weight: @batch.letter_weight,
      processing_category: @batch.letter_processing_category,
      usps_mailer_id: @batch.mailer_id,
      return_address: @batch.letter_return_address,
      return_address_name: @batch.letter_return_address_name,
      recipient_email: get(row, "email"),
      rubber_stamps: get(row, "rubber_stamps"),
      tags: @batch.tags,
      user: @batch.user,
    )
  end
end
