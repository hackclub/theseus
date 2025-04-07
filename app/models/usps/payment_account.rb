# == Schema Information
#
# Table name: usps_payment_accounts
#
#  id                :bigint           not null, primary key
#  account_number    :string
#  account_type      :integer
#  manifest_mid      :string
#  name              :string
#  permit_number     :string
#  permit_zip        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  usps_mailer_id_id :bigint           not null
#
# Indexes
#
#  index_usps_payment_accounts_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
class USPS::PaymentAccount < ApplicationRecord
  belongs_to :usps_mailer_id, class_name: "USPS::MailerId"

  enum :account_type, {
    EPS: 0,
    PERMIT: 1
    # METER: 2 # someday.... someday i will be a PC Postage vendor..,,,..,
  }

  def display_name
    case account_type
    when "EPS"
      "#{name} (#{obscured_last_4(account_number)})"
    when "PERMIT"
      "#{name} (#{permit_number} @ #{permit_zip})"
    else
      name
    end
  end

  def obscured_last_4(text)
    last_4 = text.to_s[-4..]
    "••••#{last_4}"
  end

  validates :account_type, presence: true
  validates :account_number, presence: true, if: :EPS?
  validates :permit_number, presence: true, if: :PERMIT?
  validates :permit_zip, presence: true, if: :PERMIT?


  def create_payment_token
    roles = [
      {
        roleName: "PAYER",
        CRID: usps_mailer_id.crid,
        MID: usps_mailer_id.mid,
        accountType: account_type.to_s,
        accountNumber: account_number,
        permitNumber: permit_number,
        permitZIP: permit_zip,
        manifestMID: manifest_mid || usps_mailer_id.mid
      }.compact_blank,
      {
        roleName: "LABEL_OWNER",
        CRID: usps_mailer_id.crid,
        MID: usps_mailer_id.mid,
        manifestMID: manifest_mid || usps_mailer_id.mid
      },
      {
        roleName: "MAIL_OWNER",
        CRID: usps_mailer_id.crid,
        MID: usps_mailer_id.mid,
        manifestMID: manifest_mid || usps_mailer_id.mid
      }
    ]
    USPS::APIService.create_payment_token(roles:)
  end
end
