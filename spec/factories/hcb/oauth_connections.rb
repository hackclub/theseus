FactoryBot.define do
  factory :hcb_oauth_connection, class: "HCB::OauthConnection" do
    association :user
    access_token { "fake-access-token" }
    refresh_token { "fake-refresh-token" }
  end
end
