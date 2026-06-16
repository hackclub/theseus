# == Schema Information
#
# Table name: public_users
#
#  id               :bigint           not null, primary key
#  email            :string
#  opted_out_of_map :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hca_id           :string
#
# Indexes
#
#  index_public_users_on_hca_id  (hca_id) UNIQUE
#
class Public::User < ApplicationRecord
  has_many :login_codes
  include PublicIdentifiable

  set_public_id_prefix :uzr

  def create_login_code = login_codes.create!

  def self.from_hack_club_auth(auth_hash)
    hca_id = auth_hash.dig("uid")
    return nil unless hca_id

    email = auth_hash.dig("info", "email")

    user = find_by(hca_id: hca_id)
    user ||= find_by(email: email) if email.present?
    user ||= new

    user.hca_id = hca_id
    user.email = email if email.present?
    user.save!
    user
  end
end
