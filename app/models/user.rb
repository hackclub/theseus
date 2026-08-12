# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  can_impersonate_public :boolean
#  can_use_indicia        :boolean          default(FALSE), not null
#  can_warehouse          :boolean
#  email                  :string
#  icon_url               :string
#  is_admin               :boolean
#  is_warehouse_czar      :boolean          default(FALSE), not null
#  settings               :jsonb            not null
#  username               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  hca_id                 :string
#  home_mid_id            :bigint           default(1), not null
#  home_return_address_id :bigint           default(1), not null
#  slack_id               :string
#
# Indexes
#
#  index_users_on_hca_id                  (hca_id) UNIQUE
#  index_users_on_home_mid_id             (home_mid_id)
#  index_users_on_home_return_address_id  (home_return_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (home_mid_id => usps_mailer_ids.id)
#  fk_rails_...  (home_return_address_id => return_addresses.id)
#
class User < ApplicationRecord
  has_paper_trail

  has_many :warehouse_templates, class_name: "Warehouse::Template", inverse_of: :user
  has_many :return_addresses, dependent: :destroy
  has_many :letters
  has_many :batches
  has_many :letter_queues, dependent: :destroy, class_name: "Letter::Queue"
  has_one :hcb_oauth_connection, class_name: "HCB::OauthConnection", dependent: :destroy
  has_many :hcb_payment_accounts, class_name: "HCB::PaymentAccount", dependent: :destroy
  belongs_to :home_mid, class_name: "USPS::MailerId", optional: true
  belongs_to :home_return_address, class_name: "ReturnAddress", optional: true

  include PublicIdentifiable

  set_public_id_prefix "usr"

  def admin? = is_admin
  def warehouse_czar? = is_warehouse_czar
  def can_use_indicia? = can_use_indicia

  def hcb_connected? = hcb_oauth_connection.present? && !hcb_oauth_connection.invalidated?

  def hcb_connection_invalidated? = hcb_oauth_connection&.invalidated? || false

  def setting(key)
    settings&.dig(key.to_s)
  end

  def update_setting(key, value)
    update!(settings: (settings || {}).merge(key.to_s => value))
  end

  def make_admin! = update!(is_admin: true)

  def remove_admin! = update!(is_admin: false)

  def self.from_hack_club_auth(auth_hash)
    hca_id = auth_hash.dig("uid")
    return nil unless hca_id

    # Try to find by hca_id first
    user = find_by(hca_id: hca_id)

    # If not found, try to migrate from slack_id
    unless user
      slack_id = auth_hash.dig("extra", "raw_info", "slack_id")
      if slack_id.present?
        user = find_by(slack_id: slack_id)
        if user
          # Migrate user to use hca_id
          user.hca_id = hca_id
        end
      end
    end

    return nil unless user

    user.email = auth_hash.dig("info", "email")
    user.username ||= auth_hash.dig("info", "name")

    user.save!
    user
  end
end
