# == Schema Information
#
# Table name: public_impersonations
#
#  id            :bigint           not null, primary key
#  justification :string
#  target_email  :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_public_impersonations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Public::Impersonation < ApplicationRecord
  belongs_to :user
end
