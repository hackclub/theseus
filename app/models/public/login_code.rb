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
class Public::LoginCode < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :valid, -> { where("expires_at > ? AND used_at IS NULL", Time.current) }

  TOKEN = ExternalToken.new("lc")

  def mark_used!
    update!(used_at: Time.current)
  end

  def to_param
    token
  end

  private

  def generate_token
    self.token ||= TOKEN.generate
  end

  def set_expiration
    self.expires_at ||= 30.minutes.from_now
  end
end
