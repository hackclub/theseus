# frozen_string_literal: true

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
#  index_hcb_payment_accounts_on_organization_id          (organization_id)
#  index_hcb_payment_accounts_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_oauth_connection_id => hcb_oauth_connections.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :billing_profile, class: "BillingProfile" do
    association :user
    oauth_connection { HCB::OauthConnection.find_by(user: user) || association(:hcb_oauth_connection, user: user) }
    organization_id { "org_test123" }
    organization_name { "Test Organization" }
  end
end
