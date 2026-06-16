# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  field_mapping               :jsonb
#  hcb_transfer_amount_cents   :integer
#  letter_height               :decimal(, )
#  letter_mailing_date         :date
#  letter_processing_category  :integer
#  letter_return_address_name  :string
#  letter_weight               :decimal(, )
#  letter_width                :decimal(, )
#  process_error               :string
#  process_options             :jsonb
#  tags                        :citext           default([]), is an Array
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  hcb_payment_account_id      :bigint
#  hcb_transfer_id             :string
#  letter_mailer_id_id         :bigint
#  letter_queue_id             :bigint
#  letter_return_address_id    :bigint
#  user_id                     :bigint           not null
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_hcb_payment_account_id    (hcb_payment_account_id)
#  index_batches_on_letter_mailer_id_id       (letter_mailer_id_id)
#  index_batches_on_letter_queue_id           (letter_queue_id)
#  index_batches_on_letter_return_address_id  (letter_return_address_id)
#  index_batches_on_tags                      (tags) USING gin
#  index_batches_on_type                      (type)
#  index_batches_on_user_id                   (user_id)
#  index_batches_on_warehouse_template_id     (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_payment_account_id => hcb_payment_accounts.id)
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (letter_queue_id => letter_queues.id)
#  fk_rails_...  (letter_return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
FactoryBot.define do
  factory :usps_mailer_id, class: "USPS::MailerId" do
    sequence(:name) { |n| "Test Mailer #{n}" }
    sequence(:crid) { |n| "CRID#{n}" }
    mid { "123456" }
    sequence_number { 0 }
    rollover_count { 0 }
  end

  factory :return_address do
    sequence(:name) { |n| "Return Address #{n}" }
    line_1 { "1 Infinite Loop" }
    city { "Cupertino" }
    state { "CA" }
    postal_code { "95014" }
    country { "US" }
  end

  factory :letter_batch, class: "Letter::Batch" do
    association :user
    association :mailer_id, factory: :usps_mailer_id
    association :letter_return_address, factory: :return_address
    letter_height { 4.125 }
    letter_width { 9.5 }
    letter_weight { 1 }
    letter_processing_category { 0 }

    transient do
      csv_content { "first_name,last_name,address,city,state,zip\nAlice,Smith,123 Main St,Burlington,VT,05401\n" }
      mapping { { "first_name" => "first_name", "last_name" => "last_name", "address" => "line_1", "city" => "city", "state" => "state", "zip" => "postal_code" } }
    end

    after(:create) do |batch, ctx|
      batch.csv.attach(io: StringIO.new(ctx.csv_content), filename: "test.csv", content_type: "text/csv")
      batch.update!(field_mapping: ctx.mapping)
    end
  end
end
