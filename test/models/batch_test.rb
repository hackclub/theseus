# == Schema Information
#
# Table name: batches
#
#  id            :bigint           not null, primary key
#  field_mapping :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_batches_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class BatchTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
