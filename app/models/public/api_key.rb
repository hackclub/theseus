# == Schema Information
#
# Table name: public_api_keys
#
#  id               :bigint           not null, primary key
#  name             :string
#  revoked_at       :datetime
#  token_bidx       :string
#  token_ciphertext :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  public_user_id   :bigint           not null
#
# Indexes
#
#  index_public_api_keys_on_public_user_id  (public_user_id)
#  index_public_api_keys_on_token_bidx      (token_bidx) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (public_user_id => public_users.id)
#
class Public::APIKey < ApplicationRecord
  has_paper_trail ignore: [ :token_ciphertext, :token_bidx ]

  include Hashid::Rails
  belongs_to :public_user, class_name: "Public::User"

  validates :token, presence: true, uniqueness: true
  validates :name, length: { maximum: 100 }

  scope :not_revoked, -> { where(revoked_at: nil).or(where(revoked_at: Time.now..)) }
  scope :accessible, -> { not_revoked }

  before_validation :generate_token, on: :create

  TOKEN = ExternalToken.new("apk")

  has_encrypted :token
  blind_index :token

  def revoke! = update!(revoked_at: Time.now)

  def revoked? = revoked_at.present?

  def active? = !revoked?

  def abbreviated = "#{token[..15]}.....#{token[-4..]}"

  private

  def generate_token
    self.token ||= TOKEN.generate
  end
end
