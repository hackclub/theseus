# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  field_mapping               :jsonb
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  user_id                     :bigint           not null
#  warehouse_purpose_code_id   :bigint
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_type                       (type)
#  index_batches_on_user_id                    (user_id)
#  index_batches_on_warehouse_purpose_code_id  (warehouse_purpose_code_id)
#  index_batches_on_warehouse_template_id      (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_purpose_code_id => warehouse_purpose_codes.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
class Letter::Batch < Batch
  self.inheritance_column = 'type'
  default_scope { where(type: 'letters') }

  # Add batch-level letter specifications
  attribute :letter_height, :decimal
  attribute :letter_width, :decimal
  attribute :letter_weight, :decimal

  validates :letter_height, :letter_width, :letter_weight, presence: true, numericality: { greater_than: 0 }

  def self.model_name
    Batch.model_name
  end

  def process!
    # TODO: Implement letter processing
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

  def build_address(row)
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
    letter = letters.build(
      extra_data: row[field_mapping['extra_data']],
      height: letter_height,
      width: letter_width,
      weight: letter_weight
    )

    # Associate letter with address
    letter.address = address
  end
end 
