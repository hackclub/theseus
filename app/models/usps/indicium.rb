# == Schema Information
#
# Table name: usps_indicia
#
#  id                      :bigint           not null, primary key
#  fees                    :decimal(, )
#  flirted                 :boolean
#  mailing_date            :date
#  nonmachinable           :boolean
#  postage                 :decimal(, )
#  postage_weight          :float
#  processing_category     :integer
#  raw_json_response       :jsonb
#  usps_sku                :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  letter_id               :bigint
#  usps_payment_account_id :bigint           not null
#
# Indexes
#
#  index_usps_indicia_on_letter_id                (letter_id)
#  index_usps_indicia_on_usps_payment_account_id  (usps_payment_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (letter_id => letters.id)
#  fk_rails_...  (usps_payment_account_id => usps_payment_accounts.id)
#
class USPS::Indicium < ApplicationRecord
  enum :processing_category, {
    letter: 0,
    flat: 1
  }

  has_one :payment_account
end
