# == Schema Information
#
# Table name: usps_iv_mtr_raw_json_batches
#
#  id               :bigint           not null, primary key
#  payload          :jsonb
#  processed        :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  message_group_id :string
#
class USPS::IVMTR::RawJSONBatch < ApplicationRecord
  has_many :events, class_name: "USPS::IVMTR::Event"
end
