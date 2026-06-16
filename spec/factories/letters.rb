FactoryBot.define do
  factory :letter do
    association :batch, factory: :letter_batch
    association :address
    association :user
    association :usps_mailer_id, factory: :usps_mailer_id
    association :return_address
    height { 4.125 }
    width { 9.5 }
    weight { 1 }
    processing_category { "letter" }
    postage_type { "stamps" }
    mailing_date { 1.week.from_now.to_date }
  end
end
