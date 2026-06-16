# == Schema Information
#
# Table name: hcb_payment_accounts
#
#  id                      :bigint           not null, primary key
#  organization_name       :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  hcb_oauth_connection_id :bigint           not null
#  organization_id         :string
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_hcb_payment_accounts_on_hcb_oauth_connection_id  (hcb_oauth_connection_id)
#  index_hcb_payment_accounts_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_oauth_connection_id => hcb_oauth_connections.id)
#  fk_rails_...  (user_id => users.id)
#
class HCB::PaymentAccount < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :oauth_connection, class_name: "HCB::OauthConnection", foreign_key: :hcb_oauth_connection_id

  BLOCKED_ORGANIZATION_IDS = %w[hq-usps-ops].freeze

  validates :organization_id, presence: true, uniqueness: { scope: :user_id }
  validates :organization_name, presence: true
  validate :organization_not_blocked

  def display_name = organization_name

  private

  def organization_not_blocked
    if BLOCKED_ORGANIZATION_IDS.include?(organization_id)
      errors.add(:organization_id, "is not allowed for payment accounts")
    end
  end

  public

  def self.theseus_client
    HCBV4::Client.from_credentials(
      client_id: ENV.fetch("HCB_CLIENT_ID"),
      client_secret: ENV.fetch("HCB_CLIENT_SECRET"),
      access_token: ENV.fetch("HCB_SERVICE_ACCESS_TOKEN"),
      refresh_token: ENV.fetch("HCB_SERVICE_REFRESH_TOKEN"),
    )
  end

  def self.refund_to_organization!(organization_id:, amount_cents:, name:, memo: nil)
    result = theseus_client.create_disbursement(
      event_id: ENV.fetch("HCB_RECIPIENT_ORG_ID"),
      to_organization_id: organization_id,
      amount_cents: amount_cents,
      name: name,
    )
    if memo && result.transaction_id
      theseus_client.update_transaction(
        result.transaction_id,
        event_id: ENV.fetch("HCB_RECIPIENT_ORG_ID"),
        memo: memo
      )
    end
    result
  end

  def client
    oauth_connection.client
  end

  def organization
    client.organization!(organization_id)
  end

  def create_disbursement!(amount_cents:, name:, memo: nil)
    result = client.create_disbursement(
      event_id: organization_id,
      to_organization_id: ENV.fetch("HCB_RECIPIENT_ORG_ID"),
      amount_cents: amount_cents,
      name: name,
    )
    if memo && result.transaction_id
      client.update_transaction(result.transaction_id, event_id: organization_id, memo: memo)
    end
    result
  end
end
