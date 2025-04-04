# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  field_mapping               :jsonb
#  letter_height               :decimal(, )
#  letter_weight               :decimal(, )
#  letter_width                :decimal(, )
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  letter_mailer_id_id         :bigint
#  user_id                     :bigint           not null
#  warehouse_purpose_code_id   :bigint
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_letter_mailer_id_id        (letter_mailer_id_id)
#  index_batches_on_type                       (type)
#  index_batches_on_user_id                    (user_id)
#  index_batches_on_warehouse_purpose_code_id  (warehouse_purpose_code_id)
#  index_batches_on_warehouse_template_id      (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_purpose_code_id => warehouse_purpose_codes.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
class Letter::Batch < Batch
  self.inheritance_column = "type"
  # default_scope { where(type: 'letters') }
  has_many :letters, dependent: :destroy
  belongs_to :mailer_id, class_name: "USPS::MailerId", foreign_key: "letter_mailer_id_id", optional: true
  belongs_to :letter_return_address, class_name: "ReturnAddress", optional: true

  # Add ActiveStorage attachment for the batch label PDF
  has_one_attached :pdf_label

  # Add batch-level letter specifications
  attribute :letter_height, :decimal
  attribute :letter_width, :decimal
  attribute :letter_weight, :decimal
  attr_accessor :template, :template_cycle

  validates :letter_height, :letter_width, :letter_weight, presence: true, numericality: { greater_than: 0 }
  validates :mailer_id, presence: true
  validates :letter_return_address, presence: true, on: :process

  def self.model_name
    Batch.model_name
  end

  # Directly attach a PDF to this batch
  def attach_pdf(pdf_data)
    io = StringIO.new(pdf_data)

    pdf_label.attach(
      io: io,
      filename: "label_batch_#{Time.now.to_i}.pdf",
      content_type: "application/pdf"
    )
  end

  def process!(options = {})
    return false unless fields_mapped?
    # Generate PDF labels with the provided options
    generate_labels(options)

    mark_processed!
  end

  def total_cost
    0 # TODO: Implement letter cost calculation
  end

  private

  def address_fields
    # Only include address fields and rubber_stamps for letter mapping
    [ "rubber_stamps" ]
  end

  def build_mapping(row)
    address = build_address(row)

    # Build letter with batch-level specs and extra data
    letters.build(
      height: letter_height,
      width: letter_width,
      weight: letter_weight,
      recipient_email: row[field_mapping["email"]],
      address: address,
      usps_mailer_id: mailer_id,
      return_address: letter_return_address,
      rubber_stamps: row[field_mapping["rubber_stamps"]]
    )
  end

  def generate_labels(options = {})
    return unless letters.any?

    # Preload associations to avoid N+1 queries
    preloaded_letters = letters.includes(:address, :usps_mailer_id)

    # Build options for label generation
    label_options = {}

    # Add template information
    if template_cycle.present?
      label_options[:template_cycle] = template_cycle
    elsif template.present?
      label_options[:template] = template
    end

    # Use the SnailMail service to generate labels
    pdf = SnailMail::Service.generate_batch_labels(
      preloaded_letters,
      label_options.merge(options)
    )

    # Directly attach the PDF to this batch
    attach_pdf(pdf.render)

    # Return the PDF
    pdf
  end
end
