# == Schema Information
#
# Table name: letter_queues
#
#  id                         :bigint           not null, primary key
#  include_qr_code            :boolean          default(TRUE)
#  letter_height              :decimal(, )
#  letter_mailing_date        :date
#  letter_processing_category :integer
#  letter_return_address_name :string
#  letter_weight              :decimal(, )
#  letter_width               :decimal(, )
#  name                       :string
#  postage_type               :string
#  slug                       :string
#  tags                       :citext           default([]), is an Array
#  template                   :string
#  type                       :string
#  user_facing_title          :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  hcb_payment_account_id     :bigint
#  letter_mailer_id_id        :bigint
#  letter_return_address_id   :bigint
#  user_id                    :bigint           not null
#  usps_payment_account_id    :bigint
#
# Indexes
#
#  index_letter_queues_on_hcb_payment_account_id    (hcb_payment_account_id)
#  index_letter_queues_on_letter_mailer_id_id       (letter_mailer_id_id)
#  index_letter_queues_on_letter_return_address_id  (letter_return_address_id)
#  index_letter_queues_on_type                      (type)
#  index_letter_queues_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_payment_account_id => hcb_payment_accounts.id)
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (letter_return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (usps_payment_account_id => usps_payment_accounts.id)
#
class Letter::InstantQueue < Letter::Queue
  # Validations
  validates :template, presence: true
  validates :postage_type, presence: true, inclusion: { in: %w[indicia stamps international_origin] }
  validates :usps_payment_account_id, presence: true, if: :indicia?
  validates :hcb_payment_account_id, presence: true, if: :indicia?

  # Associations
  belongs_to :usps_payment_account, class_name: "USPS::PaymentAccount", optional: true
  belongs_to :billing_profile, class_name: "BillingProfile", foreign_key: :hcb_payment_account_id, optional: true

  # Scopes
  default_scope { where(type: "Letter::InstantQueue") }

  # Methods
  def indicia? = postage_type == "indicia"

  def process_letter_instantly!(address, params = {})
    Rails.logger.info("Starting process_letter_instantly! with postage_type: #{postage_type}")

    letter = letters.create!(
      address: address,
      height: letter_height,
      width: letter_width,
      weight: letter_weight,
      return_address: letter_return_address,
      return_address_name: letter_return_address_name,
      usps_mailer_id: letter_mailer_id,
      processing_category: letter_processing_category,
      tags: tags,
      aasm_state: "pending",
      postage_type: postage_type,
      mailing_date: Date.current + 1.day,
      **params,
    )

    if indicia?
      begin
        USPS::IndiciumPurchase.new(
          letter: letter,
          usps_account: USPS::PaymentAccount.find(usps_payment_account_id),
          billing_profile: billing_profile,
          name_suffix: " via queue #{name} (#{slug})",
        ).call
      rescue Billing::Rejected, Billing::InFlight => e
        # No money moved and the indicium was cleaned up; the letter is the only trace.
        letter.destroy!
        raise "HCB payment failed: #{e.message}"
      end
      # Any other failure (Unconfirmed, Unrecorded, PurchaseFailed) leaves the
      # letter and indicium in place as the audit trail and propagates.
    end

    # Phase 3: post-processing
    letter.generate_label(
      template: template,
      include_qr_code: include_qr_code,
    )
    letter
  end
end
