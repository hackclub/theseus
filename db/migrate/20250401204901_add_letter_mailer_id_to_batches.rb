class AddLetterMailerIdToBatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :letter_mailer_id, null: true, foreign_key: { to_table: :usps_mailer_ids }
  end
end
