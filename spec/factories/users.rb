# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  can_impersonate_public :boolean
#  can_use_indicia        :boolean          default(FALSE), not null
#  can_warehouse          :boolean
#  email                  :string
#  icon_url               :string
#  is_admin               :boolean
#  is_warehouse_czar      :boolean          default(FALSE), not null
#  settings               :jsonb            not null
#  username               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  hca_id                 :string
#  home_mid_id            :bigint           default(1), not null
#  home_return_address_id :bigint           default(1), not null
#  slack_id               :string
#
# Indexes
#
#  index_users_on_hca_id                  (hca_id) UNIQUE
#  index_users_on_home_mid_id             (home_mid_id)
#  index_users_on_home_return_address_id  (home_return_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (home_mid_id => usps_mailer_ids.id)
#  fk_rails_...  (home_return_address_id => return_addresses.id)
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@test.com" }
    association :home_mid, factory: :usps_mailer_id
    association :home_return_address, factory: :return_address
  end
end
