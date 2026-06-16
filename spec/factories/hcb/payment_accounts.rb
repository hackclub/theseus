# == Schema Information
#
# Table name: hcb_payment_accounts
#
#  id                      :bigint           not null, primary key
#  organization_name       :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  hcb_oauth_connection_id :bigint           not null
#  organization_id         :string
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_hcb_payment_accounts_on_hcb_oauth_connection_id  (hcb_oauth_connection_id)
#  index_hcb_payment_accounts_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_oauth_connection_id => hcb_oauth_connections.id)
#  fk_rails_...  (user_id => users.id)
#
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
