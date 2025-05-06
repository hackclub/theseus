class AddLetterAttributesToLetterQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :letter_queues, :letter_height, :decimal, if_not_exists: true
    add_column :letter_queues, :letter_width, :decimal, if_not_exists: true
    add_column :letter_queues, :letter_weight, :decimal, if_not_exists: true
    add_column :letter_queues, :letter_processing_category, :integer, if_not_exists: true
    add_reference :letter_queues, :letter_mailer_id, foreign_key: { to_table: :usps_mailer_ids }, if_not_exists: true
    add_reference :letter_queues, :letter_return_address, foreign_key: { to_table: :return_addresses }, if_not_exists: true
    add_column :letter_queues, :letter_return_address_name, :string, if_not_exists: true
    add_column :letter_queues, :user_facing_title, :string, if_not_exists: true
    add_column :letter_queues, :tags, :citext, array: true, default: [], if_not_exists: true
  end
end
