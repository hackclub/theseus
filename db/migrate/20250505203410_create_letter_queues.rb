class CreateLetterQueues < ActiveRecord::Migration[8.0]
  def change
    create_table :letter_queues do |t|
      t.string :name
      t.string :slug
      t.references :user, null: false, foreign_key: true
      t.decimal :letter_height
      t.decimal :letter_width
      t.decimal :letter_weight
      t.integer :letter_processing_category
      t.date :letter_mailing_date
      t.references :letter_mailer_id, foreign_key: { to_table: :usps_mailer_ids }
      t.references :letter_return_address, foreign_key: { to_table: :return_addresses }
      t.string :letter_return_address_name
      t.string :user_facing_title
      t.citext :tags, array: true, default: []

      t.timestamps
    end
  end
end
