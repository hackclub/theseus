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

    # Phase 1: create letter and indicium in a transaction
    letter = nil
    indicium = nil
    ActiveRecord::Base.transaction do
      letter = letters.build(
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
      letter.save!

      if indicia?
        usps_payment_account = USPS::PaymentAccount.find(usps_payment_account_id)
        indicium = USPS::Indicium.create!(
          letter: letter,
          payment_account: usps_payment_account,
          billing_profile: billing_profile,
          mailing_date: letter.mailing_date,
        )
      end
    end

    # Phase 2: external calls outside transaction (HCB charge, USPS buy)
    if indicium
      cost_cents = (letter.postage * 100).ceil

      # Charge HCB
      transfer_service = HCB::TransferService.new(
        billing_profile: billing_profile,
        amount_cents: cost_cents,
        name: "Postage for #{letter.public_id} #{indicium.public_id} (#{slug}) #{Rails.application.routes.url_helpers.letter_path(letter)}",
        memo: "[theseus] postage for a #{letter.processing_category} via queue #{name}",
      )
      transfer = transfer_service.call
      unless transfer
        # HCB charge failed — destroy indicium (no money moved) and the letter
        indicium.destroy!
        letter.destroy!
        raise "HCB payment failed: #{transfer_service.errors.join(', ')}"
      end

      # Record billing — these are committed and survive even if USPS buy fails
      transaction_id = transfer.respond_to?(:id) ? transfer.id : transfer.to_s
      indicium.update!(hcb_transfer_id: transfer.id)
      hcb_xfer = HCB::Transfer.create!(
        billing_profile: billing_profile,
        amount_cents: cost_cents,
        state: :completed,
        hcb_transaction_id: transaction_id,
      )
      indicium.ledger_entries.create!(
        billing_profile: billing_profile,
        category: :indicia,
        amount_cents: cost_cents,
        state: :settled,
        settled_at: Time.current,
        hcb_transfer: hcb_xfer,
      )

      # Buy from USPS
      begin
        indicium.buy!
      rescue => e
        if indicium.raw_json_response.present?
          # USPS already sold us postage — do NOT destroy or refund.
          Sentry.capture_exception(e, level: :fatal, tags: { money: true, critical: true },
            extra: { indicium_id: indicium.id, letter_id: letter.id, response: indicium.raw_json_response })
          raise e
        else
          # USPS API never went through, safe to refund HCB
          refund_result = BillingProfile.refund_to_organization!(
            organization_id: billing_profile.organization_id,
            amount_cents: cost_cents,
            name: "Refund for #{letter.public_id} #{indicium.public_id} #{Rails.application.routes.url_helpers.letter_path(letter)}",
            memo: "[theseus] postage refund for a #{letter.processing_category}",
          )
          refund_tx_id = refund_result.respond_to?(:id) ? refund_result.id : refund_result.try(:transaction_id)
          refund_xfer = HCB::Transfer.create!(
            billing_profile: billing_profile,
            amount_cents: cost_cents,
            state: :completed,
            hcb_transaction_id: refund_tx_id,
          )
          indicium.ledger_entries.each { |le| le.refund!(refund_xfer) }
          # Don't destroy indicium or letter — they have refunded billing entries.
          # The indicium stays as an audit trail; the letter stays in pending state.
          raise e
        end
      end

      letter.reload
      unless letter.usps_indicium.present?
        raise "Failed to associate indicium with letter"
      end
    end

    # Phase 3: post-processing
    letter.generate_label(
      template: template,
      include_qr_code: include_qr_code,
    )
    letter
  end
end
