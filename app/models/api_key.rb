# == Schema Information
#
# Table name: api_keys
#
#  id                 :bigint           not null, primary key
#  may_impersonate    :boolean
#  name               :string
#  pii                :boolean
#  qz_only            :boolean
#  revoked_at         :datetime
#  token_bidx         :string
#  token_ciphertext   :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  billing_profile_id :bigint
#  user_id            :bigint           not null
#
# Indexes
#
#  index_api_keys_on_billing_profile_id  (billing_profile_id)
#  index_api_keys_on_token_bidx          (token_bidx) UNIQUE
#  index_api_keys_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (billing_profile_id => hcb_payment_accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class APIKey < ApplicationRecord
  has_paper_trail ignore: [ :token_ciphertext, :token_bidx ]

  belongs_to :user
  belongs_to :billing_profile, class_name: "BillingProfile", foreign_key: :billing_profile_id, optional: true

  validates :token, presence: true, uniqueness: true

  scope :not_revoked, -> { where(revoked_at: nil).or(where(revoked_at: Time.now..)) }
  scope :accessible, -> { not_revoked }

  before_validation :generate_token, on: :create

  TOKEN = ExternalToken.new("api")

  has_encrypted :token
  blind_index :token

  def pretty_name = "#{user.username}@#{name}"

  def revoke! = update!(revoked_at: Time.now)

  def revoked? = revoked_at.present?

  def active? = !revoked?

  def abbreviated = "#{token[..15]}.....#{token[-5..]}"

  private

  def generate_token
    self.token ||= TOKEN.generate
  end
end
