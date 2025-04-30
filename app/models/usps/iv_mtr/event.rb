# == Schema Information
#
# Table name: usps_iv_mtr_events
#
#  id           :bigint           not null, primary key
#  happened_at  :datetime
#  opcode       :string
#  payload      :jsonb
#  zip_code     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  batch_id     :bigint           not null
#  letter_id    :bigint
#  mailer_id_id :bigint           not null
#
# Indexes
#
#  index_usps_iv_mtr_events_on_batch_id      (batch_id)
#  index_usps_iv_mtr_events_on_letter_id     (letter_id)
#  index_usps_iv_mtr_events_on_mailer_id_id  (mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => usps_iv_mtr_raw_json_batches.id)
#  fk_rails_...  (letter_id => letters.id) ON DELETE => nullify
#  fk_rails_...  (mailer_id_id => usps_mailer_ids.id)
#
class USPS::IVMTR::Event < ApplicationRecord
  include PublicIdentifiable
  set_public_id_prefix 'mtr'

  
  belongs_to :letter, optional: true
  belongs_to :batch, class_name: "USPS::IVMTR::RawJSONBatch"
  belongs_to :mailer_id, class_name: "USPS::MailerId"

  after_create :notify_slack

  scope :bogons, -> { where(letter_id: nil) }
  scope :by_scan_datetime, -> { order(scan_datetime: :desc) }

  def bogon?
    letter.nil?
  end

  def hydrated
    @h ||= IvyMeter::Event::PieceEvent.from_json(payload || {})
  end

  def scan_datetime
    hydrated.scan_datetime
  end

  def scan_facility
    {
      name: hydrated.scan_facility_name,
      city: hydrated.scan_facility_city,
      state: hydrated.scan_facility_state,
      zip: hydrated.scan_facility_zip
    }
  end

  def mail_phase
    hydrated.mail_phase
  end

  def scan_event_code
    hydrated.scan_event_code
  end

  def handling_event_type
    hydrated.handling_event_type
  end

  def handling_event_type_description
    hydrated.handling_event_type_description
  end

  def imb_serial_number
    hydrated.imb_serial_number
  end

  def imb_mid
    hydrated.imb_mid
  end

  def imb_stid
    hydrated.imb_stid
  end

  def imb
    hydrated.imb
  end

  def machine_info
    {
      name: hydrated.machine_name,
      id: hydrated.machine_id
    }
  end

  def self.find_or_create_from_payload(payload, batch_id, mailer_id_id)
    event = IvyMeter::Event::PieceEvent.from_json(payload)
    letter = Letter.find_by_imb_sn(event.imb_serial_number, USPS::MailerId.find(mailer_id_id)) if event.imb_serial_number

    create!(
      payload: payload,
      batch_id: batch_id,
      mailer_id_id: mailer_id_id,
      letter_id: letter&.id,
      happened_at: event.scan_datetime,
      opcode: event.scan_event_code,
      zip_code: event.scan_facility_zip
    )
  end

  private

  def notify_slack
    USPS::IVMTR::NotifySlackJob.perform_later(self)
  end
end
