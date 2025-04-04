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

  def self.find_by_imb_sn(imb_sn)
    where(imb_serial_number: imb_sn.to_i).order(imb_rollover_count: :desc).first
  end

  private

  def set_imb_sequence
    sn, rollover = usps_mailer_id.next_sn_and_rollover
    update_columns(
      imb_serial_number: sn,
      imb_rollover_count: rollover
    )
  end
end
