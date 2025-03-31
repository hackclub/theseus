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
class Batch < ApplicationRecord
  belongs_to :user
  has_one_attached :csv
end
