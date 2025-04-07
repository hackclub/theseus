class AddMailingDateToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :mailing_date, :date
  end
end
