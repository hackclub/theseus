# == Schema Information
#
# Table name: usps_indicia
#
#  id                      :bigint           not null, primary key
#  fees                    :decimal(, )
#  flirted                 :boolean
#  mailing_date            :date
#  nonmachinable           :boolean
#  postage                 :decimal(, )
#  postage_weight          :float
#  processing_category     :integer
#  raw_json_response       :jsonb
#  usps_sku                :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  hcb_payment_account_id  :bigint
#  hcb_transfer_id         :string
#  letter_id               :bigint
#  usps_payment_account_id :bigint           not null
#
# Indexes
#
#  index_usps_indicia_on_hcb_payment_account_id   (hcb_payment_account_id)
#  index_usps_indicia_on_letter_id                (letter_id)
#  index_usps_indicia_on_usps_payment_account_id  (usps_payment_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_payment_account_id => hcb_payment_accounts.id)
#  fk_rails_...  (letter_id => letters.id)
#  fk_rails_...  (usps_payment_account_id => usps_payment_accounts.id)
#
class USPS::Indicium < ApplicationRecord
  include PublicIdentifiable
  set_public_id_prefix "ind"

  enum :processing_category, {
    letter: 0,
    flat: 1,
  }

  belongs_to :payment_account, foreign_key: :usps_payment_account_id
  belongs_to :letter, optional: true
  belongs_to :hcb_payment_account, class_name: "HCB::PaymentAccount", optional: true

  def buy!(payment_token = nil)
    raise ArgumentError, "for what?" unless letter
    payment_token ||= payment_account.create_payment_token

    common_opts = {
      payment_token:,
      processing_category: usps_proc_cat(letter.processing_category),
      weight: letter.weight.to_f,
      mailing_date: letter.mailing_date,
      length: letter.width.to_f,
      height: letter.height.to_f,
      thickness: 0.1,
      non_machinable_indicators: letter.non_machinable? ? { isRigid: true } : nil,
      image_type: "SVG",
    }.compact

    response = if letter.address.us?
      USPS::APIService.create_fcm_indicia(**common_opts)
    else
      USPS::APIService.create_fcmi_indicia(
        destination_country_code: letter.address.country,
        **common_opts,
      )
    end

    self.raw_json_response = response

    meta = response[:indiciaMetadata]
    self.postage = meta[:postage]
    self.fees = meta[:fees]&.sum { |fee| fee[:price] }
    self.usps_sku = meta[:SKU]

    save!
  end

  def cost = (postage || 0) + (fees || 0)

  def svg = Base64.decode64(raw_json_response["indiciaImage"])

  private

  def usps_proc_cat(sym) = sym.to_s.pluralize.upcase
end
