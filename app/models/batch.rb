# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  field_mapping               :jsonb
#  letter_height               :decimal(, )
#  letter_mailing_date         :date
#  letter_processing_category  :integer
#  letter_return_address_name  :string
#  letter_weight               :decimal(, )
#  letter_width                :decimal(, )
#  process_error               :string
#  process_options             :jsonb
#  tags                        :citext           default([]), is an Array
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  hcb_payment_account_id      :bigint
#  hcb_transfer_id             :string
#  letter_mailer_id_id         :bigint
#  letter_queue_id             :bigint
#  letter_return_address_id    :bigint
#  user_id                     :bigint           not null
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_hcb_payment_account_id    (hcb_payment_account_id)
#  index_batches_on_letter_mailer_id_id       (letter_mailer_id_id)
#  index_batches_on_letter_queue_id           (letter_queue_id)
#  index_batches_on_letter_return_address_id  (letter_return_address_id)
#  index_batches_on_tags                      (tags) USING gin
#  index_batches_on_type                      (type)
#  index_batches_on_user_id                   (user_id)
#  index_batches_on_warehouse_template_id     (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_payment_account_id => hcb_payment_accounts.id)
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (letter_queue_id => letter_queues.id)
#  fk_rails_...  (letter_return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
class Batch < ApplicationRecord
  has_paper_trail

  include AASM
  include PublicIdentifiable
  set_public_id_prefix "bat"

  include Taggable

  aasm timestamps: true do
    state :awaiting_field_mapping, initial: true
    state :fields_mapped
    state :purchasing
    state :generating_labels
    state :processed
    state :failed

    event :mark_fields_mapped do
      transitions from: :awaiting_field_mapping, to: :fields_mapped
    end

    event :mark_purchasing do
      transitions from: [:fields_mapped, :failed], to: :purchasing
    end

    event :mark_generating_labels do
      transitions from: [:fields_mapped, :purchasing], to: :generating_labels
    end

    event :mark_processed do
      transitions from: [:fields_mapped, :purchasing, :generating_labels], to: :processed
      after do
        User::UpdateTasksJob.perform_later(user)
      end
    end

    event :mark_failed do
      transitions from: [:purchasing, :generating_labels], to: :failed
    end
  end

  self.inheritance_column = "type"
  belongs_to :user
  belongs_to :letter_queue, optional: true, class_name: "Letter::Queue"
  belongs_to :hcb_payment_account, class_name: "HCB::PaymentAccount", optional: true
  has_one_attached :csv
  has_one_attached :labels_pdf
  has_one_attached :pdf_document
  has_many :addresses, dependent: :destroy

  after_save :update_associated_tags, if: :saved_change_to_tags?

  def origin
    if letter_queue.present?
      "queue: #{letter_queue.name}"
    elsif csv.present?
      "csv: #{csv.filename}"
    else
      "unknown"
    end
  end

  def csv_data
    csv.open do |file|
      File.read(file, encoding: "bom|utf-8")
    end
  end

  def attach_pdf(pdf_data) = PdfAttachmentUtil.attach_pdf(pdf_data, self, :pdf_document)

  def total_cost = raise NotImplementedError, "Subclasses must implement total_cost"

  GREMLINS = [
    "‎",
    "​",
  ].join

  def csv_headers
    rows = CSV.parse(csv_data, headers: true)
    rows.headers
  end

  def csv_sample_row
    rows = CSV.parse(csv_data, headers: true)
    rows.first
  end

  private

  def update_associated_tags
    case type
    when "Letter::Batch"
      Letter.where(batch_id: id).update_all(tags: tags)
    when "Warehouse::Batch"
      Warehouse::Order.where(batch_id: id).update_all(tags: tags)
    end
  end
end
