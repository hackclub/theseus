# == Schema Information
#
# Table name: usps_iv_mtr_events
#
#  id           :bigint           not null, primary key
#  happened_at  :datetime
#  opcode       :string
#  payload      :jsonb
#  zip_code     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  batch_id     :bigint           not null
#  letter_id    :bigint
#  mailer_id_id :bigint           not null
#
# Indexes
#
#  index_usps_iv_mtr_events_on_batch_id      (batch_id)
#  index_usps_iv_mtr_events_on_letter_id     (letter_id)
#  index_usps_iv_mtr_events_on_mailer_id_id  (mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => usps_iv_mtr_raw_json_batches.id)
#  fk_rails_...  (letter_id => letters.id) ON DELETE => nullify
#  fk_rails_...  (mailer_id_id => usps_mailer_ids.id)
#
require "test_helper"

class USPS::IVMTR::EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
