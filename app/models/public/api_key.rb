class Public::APIKey < ApplicationRecord
  include Hashid::Rails
  belongs_to :public_user, class_name: "Public::User"

  validates :token, presence: true, uniqueness: true

  scope :not_revoked, -> { where(revoked_at: nil).or(where(revoked_at: Time.now..)) }
  scope :accessible, -> { not_revoked }

  before_validation :generate_token, on: :create

  TOKEN = ExternalToken.new("apk")

  has_encrypted :token
  blind_index :token

  def revoke!
    update!(revoked_at: Time.now)
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !revoked?
  end

  def abbreviated
    "#{token[..15]}.....#{token[-4..]}"
  end

  private

  def generate_token
    self.token ||= TOKEN.generate
  end
end
