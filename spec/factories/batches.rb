# frozen_string_literal: true

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
