# == Schema Information
#
# Table name: usps_payment_accounts
#
#  id                :bigint           not null, primary key
#  account_number    :string
#  account_type      :integer
#  ach               :boolean
#  manifest_mid      :string
#  name              :string
#  permit_number     :string
#  permit_zip        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  usps_mailer_id_id :bigint           not null
#
# Indexes
#
#  index_usps_payment_accounts_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
FactoryBot.define do
  factory :usps_payment_account, class: "USPS::PaymentAccount" do
    association :usps_mailer_id, factory: :usps_mailer_id
    account_type { "EPS" }
    account_number { "1234567890" }
    name { "Test EPS Account" }
  end
end
