# == Schema Information
#
# Table name: api_keys
#
#  id               :bigint           not null, primary key
#  name             :string
#  pii              :boolean
#  revoked_at       :datetime
#  token_bidx       :string
#  token_ciphertext :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_api_keys_on_token_bidx  (token_bidx) UNIQUE
#  index_api_keys_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class APIKeyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
