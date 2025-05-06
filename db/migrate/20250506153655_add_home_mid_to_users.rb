class AddHomeMidToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :home_mid, null: false, foreign_key: { to_table: :usps_mailer_ids }, default: 1
    add_reference :users, :home_return_address, null: false, foreign_key: { to_table: :return_addresses }, default: 1
  end
end
