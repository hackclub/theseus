# == Schema Information
#
# Table name: return_addresses
#
#  id          :bigint           not null, primary key
#  city        :string
#  country     :integer
#  line_1      :string
#  line_2      :string
#  name        :string
#  postal_code :string
#  shared      :boolean
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint
#
# Indexes
#
#  index_return_addresses_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ReturnAddressTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
