class AddInstantQueueAttributesToLetterQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :letter_queues, :type, :string
    add_column :letter_queues, :template, :string
    add_column :letter_queues, :postage_type, :string
    add_column :letter_queues, :usps_payment_account_id, :bigint
    add_column :letter_queues, :include_qr_code, :boolean, default: true
    add_column :letter_queues, :letter_mailing_date, :date

    add_index :letter_queues, :type
    add_foreign_key :letter_queues, :usps_payment_accounts, column: :usps_payment_account_id
  end
end
