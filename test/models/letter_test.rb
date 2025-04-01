# == Schema Information
#
# Table name: letters
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string
#  body                :text
#  extra_data          :text
#  height              :decimal(, )
#  imb_rollover_count  :integer
#  imb_serial_number   :integer
#  imb_stid            :integer
#  non_machinable      :boolean
#  postage             :decimal(, )
#  processing_category :integer
#  recipient_email     :string
#  weight              :decimal(, )
#  width               :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  address_id          :bigint           not null
#  usps_mailer_id_id   :bigint           not null
#
# Indexes
#
#  index_letters_on_address_id         (address_id)
#  index_letters_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
require "test_helper"

class LetterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
