# == Schema Information
#
# Table name: letters
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string
#  body                :text
#  extra_data          :text
#  height              :decimal(, )
#  imb_rollover_count  :integer
#  imb_serial_number   :integer
#  imb_stid            :integer
#  non_machinable      :boolean
#  postage             :decimal(, )
#  processing_category :integer
#  recipient_email     :string
#  weight              :decimal(, )
#  width               :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  address_id          :bigint           not null
#  batch_id            :bigint
#  usps_mailer_id_id   :bigint           not null
#
# Indexes
#
#  index_letters_on_address_id         (address_id)
#  index_letters_on_batch_id           (batch_id)
#  index_letters_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
class Letter < ApplicationRecord
  include PublicIdentifiable
  set_public_id_prefix "ltr"

  include HasAddress
  include CanBeBatched
  include AASM

  # Add ActiveStorage attachment for the label PDF
  has_one_attached :label
  belongs_to :return_address, optional: true

  aasm timestamps: true do
    state :pending, initial: true
    state :printed
    state :mailed
    state :received

    event :mark_printed do
      transitions from: :pending, to: :printed
    end

    event :mark_mailed do
      transitions from: :printed, to: :mailed
    end

    event :mark_received do
      transitions from: :mailed, to: :received
    end
  end

  def been_mailed?
    mailed? || received?
  end

  belongs_to :usps_mailer_id, class_name: "USPS::MailerId"

  after_create :set_imb_sequence, if: -> { address.us? }

  # Generate a label for this letter
  def generate_label(options = {})
    pdf = SnailMail::Service.generate_label(self, options)

    # Directly attach the PDF to this letter
    attach_pdf(pdf.render)

    # Save the record to persist the attachment
    save
  end

  # Directly attach a PDF to this letter
  def attach_pdf(pdf_data)
    io = StringIO.new(pdf_data)

    label.attach(
      io: io,
      filename: "label_#{Time.now.to_i}.pdf",
      content_type: "application/pdf"
    )
  end

  def flirt
    desired_price = USPS::PricingEngine.fcmi_price(
      processing_category,
      weight,
      address.country
    )
    USPS::FLIRTEngine.closest_us_price(desired_price)
  end

  def self.find_by_imb_sn(imb_sn)
    where(imb_serial_number: imb_sn.to_i).order(imb_rollover_count: :desc).first
  end

  enum :processing_category, {
    letter: 0,
    flat: 1
  }, instance_methods: false, prefix: true, suffix: true

  enum :postage_type, {
    stamps: 0,
    indicia: 1
  }, instance_methods: false

  has_one :usps_indicium, class_name: "USPS::Indicium"

  attribute :mailing_date, :date
  validates :mailing_date, presence: true, if: -> { postage_type == "indicia" }
  validate :mailing_date_not_in_past, if: -> { mailing_date.present? }
  validates :processing_category, presence: true

  before_save :set_postage

  def mailing_date_not_in_past
    if mailing_date < Date.current
      errors.add(:mailing_date, "cannot be in the past")
    end
  end

  def default_mailing_date
    now = Time.current
    today = now.to_date

    # If it's before 4PM on a business day, default to today
    if now.hour < 16 && today.on_weekday?
      today
    else
      # Otherwise, default to next business day
      next_business_day = today
      loop do
        next_business_day += 1
        break if next_business_day.on_weekday?
      end
      next_business_day
    end
  end

  private

  def set_postage
    self.postage = case postage_type
    when "indicia"
      if usps_indicium.present?
        # Use actual indicia price if indicia are bought
        usps_indicium.cost
      elsif address.us?
        # For US mail without bought indicia, use metered price
        USPS::PricingEngine.metered_price(
          processing_category,
          weight,
          non_machinable
        )
      else
        # For international mail without bought indicia, use FLIRT-ed price
        flirted = flirt
        USPS::PricingEngine.metered_price(
          flirted[:processing_category],
          flirted[:weight],
          flirted[:non_machinable]
        )
      end
    when "stamps"
      # For stamps, use stamp price for US and desired price for international
      if address.us?
        USPS::PricingEngine.domestic_stamp_price(
          processing_category,
          weight,
          non_machinable
        )
      else
        USPS::PricingEngine.fcmi_price(
          processing_category,
          weight,
          address.country
        )
      end
    end
  end

  def set_imb_sequence
    sn, rollover = usps_mailer_id.next_sn_and_rollover
    update_columns(
      imb_serial_number: sn,
      imb_rollover_count: rollover
    )
  end
end
