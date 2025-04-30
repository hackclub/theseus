# == Schema Information
#
# Table name: common_tags
#
#  id           :bigint           not null, primary key
#  implies_ysws :boolean
#  tag          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "test_helper"

class CommonTagTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
