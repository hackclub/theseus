# == Schema Information
#
# Table name: hcb_oauth_connections
#
#  id                       :bigint           not null, primary key
#  access_token_ciphertext  :text
#  expires_at               :datetime
#  invalidated_at           :datetime
#  refresh_token_ciphertext :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  index_hcb_oauth_connections_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :hcb_oauth_connection, class: "HCB::OauthConnection" do
    association :user
    access_token { "fake-access-token" }
    refresh_token { "fake-refresh-token" }
  end
end
