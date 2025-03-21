# == Schema Information
#
# Table name: usps_indicia
#
#  id                      :bigint           not null, primary key
#  mailing_date            :date
#  nonmachinable           :boolean
#  postage                 :decimal(, )
#  postage_height          :float
#  postage_length          :float
#  postage_thickness       :float
#  postage_weight          :float
#  processing_category     :integer
#  raw_usps_response       :text
#  usps_sku                :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  usps_payment_account_id :bigint           not null
#
# Indexes
#
#  index_usps_indicia_on_usps_payment_account_id  (usps_payment_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (usps_payment_account_id => usps_payment_accounts.id)
#
class USPS::Indicium < ApplicationRecord
  enum :processing_category, {
    letter: 0,
    flat: 1
  }

  has_one :payment_account
end
