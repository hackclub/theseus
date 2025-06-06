# == Schema Information
#
# Table name: letters
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string
#  body                :text
#  height              :decimal(, )
#  idempotency_key     :string
#  imb_rollover_count  :integer
#  imb_serial_number   :integer
#  mailed_at           :datetime
#  mailing_date        :date
#  metadata            :jsonb
#  non_machinable      :boolean
#  postage             :decimal(, )
#  postage_type        :integer
#  printed_at          :datetime
#  processing_category :integer
#  received_at         :datetime
#  recipient_email     :string
#  return_address_name :string
#  rubber_stamps       :text
#  tags                :citext           default([]), is an Array
#  user_facing_title   :string
#  weight              :decimal(, )
#  width               :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  address_id          :bigint           not null
#  batch_id            :bigint
#  letter_queue_id     :bigint
#  return_address_id   :bigint           not null
#  user_id             :bigint           not null
#  usps_mailer_id_id   :bigint           not null
#
# Indexes
#
#  index_letters_on_address_id         (address_id)
#  index_letters_on_batch_id           (batch_id)
#  index_letters_on_idempotency_key    (idempotency_key) UNIQUE
#  index_letters_on_imb_serial_number  (imb_serial_number)
#  index_letters_on_letter_queue_id    (letter_queue_id)
#  index_letters_on_return_address_id  (return_address_id)
#  index_letters_on_tags               (tags) USING gin
#  index_letters_on_user_id            (user_id)
#  index_letters_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (letter_queue_id => letter_queues.id)
#  fk_rails_...  (return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
class Letter < ApplicationRecord
  include PublicIdentifiable
  set_public_id_prefix "ltr"

  include HasAddress
  include CanBeBatched
  include AASM
  include Taggable
  # Add ActiveStorage attachment for the label PDF
  has_one_attached :label
  belongs_to :return_address, optional: true
  has_many :iv_mtr_events, class_name: "USPS::IVMTR::Event"
  belongs_to :user
  belongs_to :queue, class_name: "Letter::Queue", foreign_key: "letter_queue_id", optional: true

  aasm timestamps: true do
    state :queued
    state :pending, initial: true
    state :printed
    state :mailed
    state :received

    event :batch_from_queue do
      transitions from: :queued, to: :pending
    end

    event :mark_printed do
      transitions from: :pending, to: :printed
    end

    event :mark_mailed do
      transitions from: [:pending, :printed], to: :mailed
    end

    event :mark_received do
      transitions from: :mailed, to: :received
    end

    event :unreceive do
      transitions from: :received, to: :mailed
    end
  end

  def display_name
    user_facing_title || tags.compact_blank.join(", ") || public_id
  end

  def return_address_name_line
    return_address_name.presence || return_address&.name
  end

  def been_mailed?
    mailed? || received?
  end

  belongs_to :usps_mailer_id, class_name: "USPS::MailerId"

  after_create :set_imb_sequence

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
      content_type: "application/pdf",
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

  def self.find_by_imb_sn(imb_sn, mailer_id = nil)
    query = where(imb_serial_number: imb_sn.to_i)
    query = query.where(usps_mailer_id: mailer_id) if mailer_id
    query.order(imb_rollover_count: :desc).first
  end

  enum :processing_category, {
    letter: 0,
    flat: 1,
  }, instance_methods: false, prefix: true, suffix: true

  enum :postage_type, {
    stamps: 0,
    indicia: 1,
    international_origin: 2,
  }, instance_methods: false

  has_one :usps_indicium, class_name: "USPS::Indicium"

  attribute :mailing_date, :date
  validates :mailing_date, presence: true, if: -> { postage_type == "indicia" }
  validate :mailing_date_not_in_past, if: -> { mailing_date.present? }, on: :create
  validates :processing_category, presence: true
  validate :validate_postage_type_by_return_address

  before_save :set_postage

  def mailing_date_not_in_past
    if mailing_date < Date.current
      errors.add(:mailing_date, "cannot be in the past")
    end
  end

  def validate_postage_type_by_return_address
    if return_address.present? && postage_type.present?
      if return_address.us?
        if postage_type == "international_origin"
          errors.add(:postage_type, "cannot be international origin when return address is in the US")
        end
      else
        if postage_type != "international_origin"
          errors.add(:postage_type, "must be international origin when return address is not in the US")
        end
      end
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

  def to_param
    self.public_id
  end

  def events
    iv = iv_mtr_events.map do |event|
      e = event.hydrated
      {
        happened_at: event.happened_at.in_time_zone("America/New_York"),
        source: "USPS IV-MTR",
        location: "#{e.scan_facility_city}, #{e.scan_facility_state} #{e.scan_facility_zip}",
        facility: "#{e.scan_facility_name} (#{e.scan_locale_key})",
        description: "[OP#{e.opcode.code}] #{e.opcode.process_description}",
        extra_info: "#{e.handling_event_type_description} – #{e.mail_phase} – #{e.machine_name} (#{event.payload.dig("machineId") || "no ID"})",
      }
    end
    timestamps = []
    location = return_address.location
    timestamps << {
      happened_at: printed_at.in_time_zone("America/New_York"),
      source: "Hack Club",
      facility: "Mailer",
      description: "Letter printed.",
      location:,
    } if printed_at
    timestamps << {
      happened_at: mailed_at.in_time_zone("America/New_York"),
      source: "Hack Club",
      facility: "Mailer",
      description: "Letter mailed!",
      location:,
    } if mailed_at
    timestamps << {
      happened_at: received_at.in_time_zone("America/New_York"),
      source: "You!",
      facility: "Your mailbox",
      description: "You received this letter!",
      location: "wherever you live",
    } if received_at
    (iv + timestamps).sort_by { |event| event[:happened_at] }
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
        if %i(queued pending).include?(aasm.current_state)
          return 0
        end
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
            address.country,
            non_machinable
          )
        end
      when "international_origin"
        0
      end
  end

  def set_imb_sequence
    sn, rollover = usps_mailer_id.next_sn_and_rollover
    update_columns(
      imb_serial_number: sn,
      imb_rollover_count: rollover,
    )
  end
end
