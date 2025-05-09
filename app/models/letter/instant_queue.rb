class Letter::InstantQueue < Letter::Queue
  # Validations
  validates :template, presence: true
  validates :postage_type, presence: true, inclusion: { in: %w[indicia stamps] }
  validates :usps_payment_account_id, presence: true, if: :indicia?
  validates :letter_mailing_date, presence: true, if: :indicia?

  # Scopes
  default_scope { where(type: "Letter::InstantQueue") }

  # Methods
  def indicia?
    postage_type == "indicia"
  end

  def process_letter_instantly!(address, params = {})
    ActiveRecord::Base.transaction do
      # Create letter directly in pending state
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
        mailing_date: letter_mailing_date || Date.current,
        **params,
      )
      letter.save!

      # Purchase indicia if needed
      if indicia?
        payment_account = USPS::PaymentAccount.find(usps_payment_account_id)
        indicium = USPS::Indicium.new(
          letter: letter,
          payment_account: payment_account,
          mailing_date: letter.mailing_date,
        )
        indicium.buy!
      end

      # Generate label immediately
      letter.generate_label(
        template: template,
        include_qr_code: include_qr_code,
      )

      letter
    end
  end
end
