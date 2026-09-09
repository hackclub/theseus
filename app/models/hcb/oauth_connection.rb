# == Schema Information
#
# Table name: hcb_oauth_connections
#
#  id                       :bigint           not null, primary key
#  access_token_ciphertext  :text
#  expires_at               :datetime
#  invalidated_at           :datetime
#  refresh_token_ciphertext :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  index_hcb_oauth_connections_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class HCB::OauthConnection < ApplicationRecord
  has_paper_trail ignore: [ :access_token_ciphertext, :refresh_token_ciphertext ]

  belongs_to :user
  has_many :payment_accounts, dependent: :destroy

  has_encrypted :access_token, :refresh_token

  validates :user_id, uniqueness: true

  def invalidated?
    invalidated_at.present?
  end

  def invalidate!
    update!(
      invalidated_at: Time.current,
      access_token: nil,
      refresh_token: nil,
      expires_at: nil,
    )
    @client = nil
  end

  def revalidate!(token)
    update!(
      access_token: token.token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at ? Time.at(token.expires_at) : nil,
      invalidated_at: nil,
    )
    @client = nil
  end

  def client
    raise OauthConnectionInvalidatedError, "HCB connection has been invalidated — please relink your account" if invalidated?

    @client ||= HCBV4::Client.from_credentials(
      client_id: ENV.fetch("HCB_CLIENT_ID"),
      client_secret: ENV.fetch("HCB_CLIENT_SECRET"),
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: expires_at&.to_i,
      base_url: hcb_api_base,
      on_token_refresh: ->(token) {
        update!(
          access_token: token.token,
          refresh_token: token.refresh_token,
          expires_at: token.expires_at ? Time.at(token.expires_at) : nil,
        )
      }
    )
  end

  def organizations
    client.organizations
  end

  private

  def hcb_api_base
    ENV.fetch("HCB_API_BASE", "https://hcb.hackclub.com")
  end
end
