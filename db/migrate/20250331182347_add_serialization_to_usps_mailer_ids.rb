class AddSerializationToUSPSMailerIds < ActiveRecord::Migration[8.0]
  def change
    add_column :usps_mailer_ids, :rollover_count, :integer
    add_column :usps_mailer_ids, :sequence_number, :bigint
  end
end
