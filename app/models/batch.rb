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
#  letter_weight               :decimal(, )
#  letter_width                :decimal(, )
#  tags                        :citext           default([]), is an Array
#  template_cycle              :string           default([]), is an Array
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  letter_mailer_id_id         :bigint
#  letter_return_address_id    :bigint
#  user_id                     :bigint           not null
#  warehouse_purpose_code_id   :bigint
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_letter_mailer_id_id        (letter_mailer_id_id)
#  index_batches_on_letter_return_address_id   (letter_return_address_id)
#  index_batches_on_tags                       (tags) USING gin
#  index_batches_on_type                       (type)
#  index_batches_on_user_id                    (user_id)
#  index_batches_on_warehouse_purpose_code_id  (warehouse_purpose_code_id)
#  index_batches_on_warehouse_template_id      (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (letter_return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_purpose_code_id => warehouse_purpose_codes.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
class Batch < ApplicationRecord
  include AASM
  include PublicIdentifiable
  set_public_id_prefix "batch"

  include Taggable

  aasm timestamps: true do
    state :awaiting_field_mapping, initial: true
    state :fields_mapped
    state :processed

    event :mark_fields_mapped do
      transitions from: :awaiting_field_mapping, to: :fields_mapped
    end

    event :mark_processed do
      transitions from: :fields_mapped, to: :processed
    end
  end

  self.inheritance_column = "type"
  belongs_to :user
  has_one_attached :csv
  has_one_attached :labels_pdf
  has_one_attached :pdf_document
  has_many :addresses, dependent: :destroy

  after_save :update_associated_tags, if: :saved_change_to_tags?

  def attach_pdf(pdf_data)
    PdfAttachmentUtil.attach_pdf(pdf_data, self, :pdf_document)
  end

  def total_cost
    raise NotImplementedError, "Subclasses must implement total_cost"
  end

  GREMLINS = [
    "‎",
    "​",
  ].join

  def run_map!
    csv_content = csv.download
    rows = CSV.parse(csv_content, headers: true, encoding: "UTF-8", converters: [->(s) { s&.strip&.delete(GREMLINS).presence }])

    # Phase 1: Collect all address data
    address_attributes = []
    row_map = {}  # Keep rows in a hash
    Parallel.each(rows.each_with_index, in_threads: 8) do |row, i|
      begin
        # Skip rows where first_name is blank
        next if row[field_mapping["first_name"]].blank?

        address_attrs = build_address_attributes(row)
        if address_attrs
          address_attributes << address_attrs
          row_map[i] = row  # Store row in hash
        end
      rescue => e
        Rails.logger.error("Error processing row #{i} in batch #{id}: #{e.message}")
        raise
      end
    end

    # Bulk insert all addresses
    if address_attributes.any?
      now = Time.current
      address_attributes.each do |attrs|
        attrs[:created_at] = now
        attrs[:updated_at] = now
        attrs[:batch_id] = id
      end

      begin
        Address.insert_all!(address_attributes)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to insert addresses: #{e.message}")
        raise
      end

      # Phase 2: Create associated records (letters) for each address
      # Fetch all addresses we just created
      addresses = Address.where(batch_id: id).where(created_at: now).to_a

      Parallel.each(addresses.each_with_index, in_threads: 8) do |address, i|
        begin
          ActiveRecord::Base.connection_pool.with_connection do
            ActiveRecord::Base.transaction do
              build_mapping(row_map[i], address)
            end
          end
        rescue => e
          Rails.logger.error("Error creating associated records for address #{address.id} in batch #{id}: #{e.message}")
          raise
        end
      end
    end

    mark_fields_mapped
    save!
  end

  private

  def build_address_attributes(row)
    csv_country = row[field_mapping["country"]]
    country = FrickinCountryNames.find_country(csv_country)
    postal_code = row[field_mapping["postal_code"]]
    state = row[field_mapping["state"]]

    # Try AI translation if:
    # 1. Country couldn't be found by FrickinCountryNames, or
    # 2. Country is not US
    if country.nil? || country.alpha2 != "US"
      begin
        translated = AIService.fix_address(row, field_mapping)
        if translated
          # If AI translation succeeded, try to find the country again
          translated_country = FrickinCountryNames.find_country(translated[:country])
          if translated_country
            # Preserve original first_name and last_name
            translated[:first_name] = row[field_mapping["first_name"]]
            translated[:last_name] = row[field_mapping["last_name"]]
            translated[:country] = translated_country.alpha2
            return translated
          end
        end
      rescue => e
        Rails.logger.error("AI translation failed for batch #{id}: #{e.message}")
        raise
      end
    end

    # Process US addresses or fallback for failed translations
    if country&.alpha2 == "US" && postal_code.present? && postal_code.length < 5
      postal_code = postal_code.rjust(5, "0")
    end

    # Normalize state name to abbreviation if country is found
    normalized_state = if country
        FrickinCountryNames.normalize_state(country, state)
      else
        state
      end

    {
      first_name: row[field_mapping["first_name"]],
      last_name: row[field_mapping["last_name"]],
      line_1: row[field_mapping["line_1"]],
      line_2: row[field_mapping["line_2"]],
      city: row[field_mapping["city"]],
      state: normalized_state,
      postal_code: postal_code,
      country: country&.alpha2 || csv_country&.upcase, # Use FCN alpha2 if available, otherwise original country code
      phone_number: row[field_mapping["phone_number"]],
      email: row[field_mapping["email"]],
    }
  end

  def build_mapping(row, address)
    # Base class just returns the address
    address
  end

  def update_associated_tags
    case type
    when "Letter::Batch"
      Letter.where(batch_id: id).update_all(tags: tags)
    when "Warehouse::Batch"
      Warehouse::Order.where(batch_id: id).update_all(tags: tags)
    end
  end
end
