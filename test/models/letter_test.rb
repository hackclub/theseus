# == Schema Information
#
# Table name: letters
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string
#  body                :text
#  height              :decimal(, )
#  imb_rollover_count  :integer
#  imb_serial_number   :integer
#  mailed_at           :datetime
#  mailing_date        :date
#  metadata            :jsonb
#  non_machinable      :boolean
#  postage             :decimal(, )
#  postage_type        :integer
#  printed_at          :datetime
#  processing_category :integer
#  received_at         :datetime
#  recipient_email     :string
#  rubber_stamps       :text
#  tags                :citext           default([]), is an Array
#  user_facing_title   :string
#  weight              :decimal(, )
#  width               :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  address_id          :bigint           not null
#  batch_id            :bigint
#  return_address_id   :bigint           not null
#  user_id             :bigint           not null
#  usps_mailer_id_id   :bigint           not null
#
# Indexes
#
#  index_letters_on_address_id         (address_id)
#  index_letters_on_batch_id           (batch_id)
#  index_letters_on_imb_serial_number  (imb_serial_number)
#  index_letters_on_return_address_id  (return_address_id)
#  index_letters_on_tags               (tags) USING gin
#  index_letters_on_user_id            (user_id)
#  index_letters_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
require "test_helper"

class LetterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
