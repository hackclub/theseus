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
require "test_helper"

class USPS::IVMTR::RawJSONBatchTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
