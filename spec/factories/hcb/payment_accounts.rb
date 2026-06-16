FactoryBot.define do
  factory :hcb_payment_account, class: "HCB::PaymentAccount" do
    association :user
    association :oauth_connection, factory: :hcb_oauth_connection
    organization_id { "org_test123" }
    organization_name { "Test Organization" }

    after(:build) do |account|
      # Ensure the oauth_connection belongs to the same user
      account.oauth_connection.user = account.user unless account.oauth_connection.user == account.user
    end
  end
end
