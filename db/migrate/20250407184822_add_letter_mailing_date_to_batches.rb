class AddLetterMailingDateToBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :letter_mailing_date, :date
  end
end
