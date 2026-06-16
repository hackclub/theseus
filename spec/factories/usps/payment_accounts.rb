FactoryBot.define do
  factory :usps_payment_account, class: "USPS::PaymentAccount" do
    association :usps_mailer_id, factory: :usps_mailer_id
    account_type { "EPS" }
    account_number { "1234567890" }
    name { "Test EPS Account" }
  end
end
