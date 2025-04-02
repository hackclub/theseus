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
  self.inheritance_column = 'type'
  # default_scope { where(type: 'letters') }
  has_many :letters, dependent: :destroy
  belongs_to :mailer_id, class_name: 'USPS::MailerId', foreign_key: 'letter_mailer_id_id', optional: true
  
  # Add ActiveStorage attachment for the batch label PDF
  has_one_attached :pdf_label
  
  # Add batch-level letter specifications
  attribute :letter_height, :decimal
  attribute :letter_width, :decimal
  attribute :letter_weight, :decimal
  attr_accessor :template, :template_cycle

  validates :letter_height, :letter_width, :letter_weight, presence: true, numericality: { greater_than: 0 }
  validates :mailer_id, presence: true

  def self.model_name
    Batch.model_name
  end

  # Directly attach a PDF to this batch
  def attach_pdf(pdf_data)
    io = StringIO.new(pdf_data)
    
    pdf_label.attach(
      io: io,
      filename: "label_batch_#{Time.now.to_i}.pdf",
      content_type: 'application/pdf'
    )
  end

  def process!
    return false unless fields_mapped?
    # Generate PDF labels
    generate_labels
    
    mark_processed!
  end

  def total_cost
    0 # TODO: Implement letter cost calculation
  end

  private

  def address_fields
    # Only include address fields and extra_data for letter mapping
    (Address.column_names - ['id', 'created_at', 'updated_at', 'batch_id']) +
    ['extra_data']
  end

  def build_mapping(row)
    csv_country = row[field_mapping['country']]

    country = ISO3166::Country.find_country_by_alpha2(csv_country) || ISO3166::Country.find_country_by_alpha3(csv_country) || ISO3166::Country.find_country_by_any_name(csv_country)

    unless country
      raise "couldn't parse #{csv_country} as a country!"
    end

    # Build address with standard fields
    address = addresses.build(
      first_name: row[field_mapping['first_name']],
      last_name: row[field_mapping['last_name']],
      line_1: row[field_mapping['line_1']],
      line_2: row[field_mapping['line_2']],
      city: row[field_mapping['city']],
      state: row[field_mapping['state']],
      postal_code: row[field_mapping['postal_code']],
      country: country.alpha2,
      phone_number: row[field_mapping['phone_number']],
      email: row[field_mapping['email']]
    )

    # Build letter with batch-level specs and extra data
    letters.build(
      extra_data: row[field_mapping['extra_data']],
      height: letter_height,
      width: letter_width,
      weight: letter_weight,
      recipient_email: row[field_mapping['email']],
      address: address,
      usps_mailer_id: mailer_id
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
