# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  back_office            :boolean          default(FALSE)
#  can_impersonate_public :boolean
#  can_warehouse          :boolean
#  email                  :string
#  icon_url               :string
#  is_admin               :boolean
#  username               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  home_mid_id            :bigint           default(1), not null
#  home_return_address_id :bigint           default(1), not null
#  slack_id               :string
#
# Indexes
#
#  index_users_on_home_mid_id             (home_mid_id)
#  index_users_on_home_return_address_id  (home_return_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (home_mid_id => usps_mailer_ids.id)
#  fk_rails_...  (home_return_address_id => return_addresses.id)
#
class User < ApplicationRecord
  has_many :warehouse_templates, class_name: "Warehouse::Template", inverse_of: :user
  has_many :return_addresses, dependent: :destroy
  has_many :letters
  has_many :batches
  has_many :letter_queues, dependent: :destroy, class_name: "Letter::Queue"
  belongs_to :home_mid, class_name: "USPS::MailerId", optional: true
  belongs_to :home_return_address, class_name: "ReturnAddress", optional: true

  include PublicIdentifiable

  set_public_id_prefix "usr"

  def admin?
    is_admin
  end

  def make_admin!
    update!(is_admin: true)
  end

  def remove_admin!
    update!(is_admin: false)
  end

  def self.authorize_url(redirect_uri)
    params = {
      client_id: ENV["SLACK_CLIENT_ID"],
      redirect_uri: redirect_uri,
      state: SecureRandom.hex(24),
      user_scope: "users.profile:read,users:read,users:read.email",
    }

    URI.parse("https://slack.com/oauth/v2/authorize?#{params.to_query}")
  end

  def self.from_slack_token(code, redirect_uri)
    # Exchange code for token
    response = HTTP.post("https://slack.com/api/oauth.v2.access", form: {
                                                                    client_id: ENV["SLACK_CLIENT_ID"],
                                                                    client_secret: ENV["SLACK_CLIENT_SECRET"],
                                                                    code: code,
                                                                    redirect_uri: redirect_uri,
                                                                  })

    data = JSON.parse(response.body.to_s)

    return nil unless data["ok"]

    # Get user info
    user_response = HTTP.auth("Bearer #{data["authed_user"]["access_token"]}")
                        .get("https://slack.com/api/users.info?user=#{data["authed_user"]["id"]}")

    user_data = JSON.parse(user_response.body.to_s)

    return nil unless user_data["ok"]

    user = find_by(slack_id: data.dig("authed_user", "id"))
    return nil unless user

    user.email = user_data.dig("user", "profile", "email")
    user.username ||= user_data.dig("user", "profile", "username")
    user.username ||= user_data.dig("user", "profile", "display_name_normalized")
    user.icon_url = user_data.dig("user", "profile", "image_192") || user_data.dig("user", "profile", "image_72")
    # Store the OAuth data
    user.save!
    user
  end
end
