# == Schema Information
#
# Table name: public_users
#
#  id         :bigint           not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Public::UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
