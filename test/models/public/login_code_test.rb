# == Schema Information
#
# Table name: public_login_codes
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  token      :string
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_public_login_codes_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => public_users.id)
#
require "test_helper"

class Public::LoginCodeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
