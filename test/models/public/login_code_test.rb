# == Schema Information
#
# Table name: public_login_codes
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Public::LoginCodeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
