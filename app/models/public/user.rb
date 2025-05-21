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
  include PublicIdentifiable

  set_public_id_prefix :uzr

  def create_login_code
    login_codes.create!
  end
end
