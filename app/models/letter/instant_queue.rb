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
  # Postage may have been sold, or money may have moved and we don't know
  # which way. The letter and everything pointing at it stays exactly where it
  # is; a human has to look. Retrying is not safe, so the idempotency key
  # stays burned on purpose.
  class PurchaseUncertain < StandardError
    attr_reader :letter, :cause_error

    def initialize(letter, cause_error)
      @letter = letter
      @cause_error = cause_error
      super("postage for #{letter.public_id} is in an unknown state: #{cause_error.message}")
    end
  end

  # Validations
  validates :template, presence: true
  validates :postage_type, presence: true, inclusion: { in: %w[indicia stamps international_origin] }
  validates :usps_payment_account_id, presence: true, if: :indicia?
  validates :hcb_payment_account_id, presence: true, if: :indicia?
  validate :billing_profile_belongs_to_user

  # Associations
  belongs_to :usps_payment_account, class_name: "USPS::PaymentAccount", optional: true
  belongs_to :billing_profile, class_name: "BillingProfile", foreign_key: :hcb_payment_account_id, optional: true

  # Scopes
  default_scope { where(type: "Letter::InstantQueue") }

  # Methods
  def indicia? = postage_type == "indicia"

  def billing_profile_belongs_to_user
    if billing_profile.present? && billing_profile.user != user
      errors.add(:billing_profile, "must belong to the queue's user")
    end
  end

  # What each submitted letter bills the queue's owner (US rate; international varies).
  def billing_lines
    return [] unless indicia?
    category = Letter.processing_categories.key(letter_processing_category) || letter_processing_category
    cents = (USPS::PricingEngine.metered_price(category, letter_weight, false).to_d * 100).ceil
    [ Billing::Quote::Line.new(category: :indicia, label: "postage per US letter submitted", when: :later, amount_cents: cents, count: 1) ]
  rescue USPS::USPSError, Faraday::Error, OAuth2::Error, RuntimeError => e
    Rails.logger.warn("[Letter::InstantQueue] could not price #{public_id}: #{e.class}: #{e.message}")
    [ Billing::Quote::Line.new(category: :indicia, label: "postage per letter submitted, at cost", when: :later, count: 1) ]
  end

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
      rescue Billing::Unconfirmed, USPS::IndiciumPurchase::Unrecorded => e
        raise PurchaseUncertain.new(letter, e)
      rescue Billing::Rejected, Billing::InFlight, USPS::IndiciumPurchase::PurchaseFailed
        # Nothing was mailed: Rejected/InFlight never moved money, and
        # PurchaseFailed means USPS sold us nothing and the charge was credited
        # back. Free the idempotency key so the caller's retry isn't a
        # permanent 400.
        release_never_sent!(letter)
        raise
      end
    end

    # Phase 3: post-processing
    letter.generate_label(
      template: template,
      include_qr_code: include_qr_code,
    )
    letter
  end

  private

  # Nothing was mailed, so the caller must be able to retry with the same
  # idempotency key. Drop the letter if the purchase left nothing behind;
  # otherwise the indicium and its ledger entries are the record that money
  # moved and came home, so keep the row and only give the key up.
  def release_never_sent!(letter)
    if letter.reload.usps_indicium.nil?
      letter.destroy!
    else
      letter.update_columns(idempotency_key: nil)
    end
  end
end
