# == Schema Information
#
# Table name: public_users
#
#  id         :bigint           not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Public::User < ApplicationRecord
  has_many :login_codes
end
