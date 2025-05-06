class AddLetterAttributesToLetterQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :letter_queues, :letter_height, :decimal
    add_column :letter_queues, :letter_width, :decimal
    add_column :letter_queues, :letter_weight, :decimal
    add_column :letter_queues, :letter_processing_category, :integer
    add_reference :letter_queues, :letter_mailer_id, foreign_key: { to_table: :usps_mailer_ids }
    add_reference :letter_queues, :letter_return_address, foreign_key: { to_table: :return_addresses }
    add_column :letter_queues, :letter_return_address_name, :string
    add_column :letter_queues, :user_facing_title, :string
    add_column :letter_queues, :tags, :citext, array: true, default: []
  end
end
