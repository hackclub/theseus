FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@test.com" }
    association :home_mid, factory: :usps_mailer_id
    association :home_return_address, factory: :return_address
  end
end
