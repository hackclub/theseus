class AddInstantQueueAttributesToLetterQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :letter_queues, :type, :string, if_not_exists: true
    add_column :letter_queues, :template, :string, if_not_exists: true
    add_column :letter_queues, :postage_type, :string, if_not_exists: true
    add_column :letter_queues, :usps_payment_account_id, :bigint, if_not_exists: true
    add_column :letter_queues, :include_qr_code, :boolean, default: true, if_not_exists: true
    add_column :letter_queues, :letter_mailing_date, :date, if_not_exists: true

    add_index :letter_queues, :type, if_not_exists: true
    add_foreign_key :letter_queues, :usps_payment_accounts, column: :usps_payment_account_id, if_not_exists: true
  end
end
