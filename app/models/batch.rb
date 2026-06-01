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
    state :processed

    event :mark_fields_mapped do
      transitions from: :awaiting_field_mapping, to: :fields_mapped
    end

    event :mark_processed do
      transitions from: :fields_mapped, to: :processed
      after do
        User::UpdateTasksJob.perform_later(user)
      end
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

  # New method: accepts pre-mapped address data (array of hashes with address field names as keys)
  # from the client-side CSV mapper. Runs normalization and creates records.
  def import_addresses!(addresses_data)
    address_attributes = []
    row_data = {}

    Parallel.each(addresses_data.each_with_index, in_threads: 8) do |row, i|
      begin
        next if row["first_name"].blank?

        attrs = normalize_address(row)
        if attrs
          address_attributes << attrs
          row_data[i] = row
        end
      rescue => e
        Rails.logger.error("Error processing row #{i} in batch #{id}: #{e.message}")
        raise
      end
    end

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

      addresses = Address.where(batch_id: id).where(created_at: now).to_a

      Parallel.each(addresses.each_with_index, in_threads: 8) do |address, i|
        begin
          ActiveRecord::Base.connection_pool.with_connection do
            ActiveRecord::Base.transaction do
              build_mapping(row_data[i], address)
            end
          end
        rescue => e
          Rails.logger.error("Error creating associated records for address #{address.id} in batch #{id}: #{e.message}")
          raise
        end
      end
    end

    mark_fields_mapped unless fields_mapped? || processed?
    save!
  end

  def run_map!
    rows = CSV.parse(csv_data, headers: true, converters: [->(s) { s&.strip&.delete(GREMLINS).presence }])

    # Phase 1: Build address attributes in parallel with correlation tokens
    # Parallel.map returns results in input order and avoids shared mutable state
    items = Parallel.map(rows.each_with_index, in_threads: 8) do |row, i|
      begin
        next if row[field_mapping["first_name"]].blank?

        address_attrs = build_address_attributes(row)
        next unless address_attrs

        # UUID token correlates this row with its address after bulk insert
        { token: SecureRandom.uuid, row: row, attrs: address_attrs }
      rescue => e
        Rails.logger.error("Error processing row #{i} in batch #{id}: #{e.message}")
        raise
      end
    end.compact

    return mark_fields_mapped && save! if items.empty?

    # Bulk insert addresses with correlation tokens
    now = Time.current
    address_attributes = items.map do |item|
      item[:attrs].merge(batch_id: id, import_token: item[:token], created_at: now, updated_at: now)
    end

    Address.insert_all!(address_attributes)

    # Phase 2: Fetch addresses by token and create associated records
    tokens = items.map { |item| item[:token] }
    addresses_by_token = Address.where(import_token: tokens).index_by(&:import_token)

    items.each do |item|
      address = addresses_by_token.fetch(item[:token])

      ActiveRecord::Base.transaction do
        build_mapping(item[:row], address)
      end
    end

    # Clear tokens after successful mapping
    Address.where(import_token: tokens).update_all(import_token: nil)

    mark_fields_mapped
    save!
  end

  private

  # Normalize a pre-mapped address hash (keys are address field names like "first_name", "line_1", etc.)
  def normalize_address(row)
    csv_country = row["country"]
    country = FrickinCountryNames.find_country(csv_country)
    postal_code = row["postal_code"]
    state = row["state"]

    if country.nil? || country.alpha2 != "US"
      begin
        translated = AIService.fix_address_from_hash(row)
        if translated
          translated_country = FrickinCountryNames.find_country(translated[:country])
          if translated_country
            translated[:first_name] = row["first_name"]
            translated[:last_name] = row["last_name"]
            translated[:country] = translated_country.alpha2
            return translated
          end
        end
      rescue => e
        Rails.logger.error("AI translation failed for batch #{id}: #{e.message}")
        raise
      end
    end

    if country&.alpha2 == "US" && postal_code.present? && postal_code.length < 5
      postal_code = postal_code.rjust(5, "0")
    end

    normalized_state = if country
        FrickinCountryNames.normalize_state(country, state)
      else
        state
      end

    {
      first_name: row["first_name"],
      last_name: row["last_name"],
      line_1: row["line_1"],
      line_2: row["line_2"],
      city: row["city"],
      state: normalized_state,
      postal_code: postal_code,
      country: country&.alpha2 || csv_country&.upcase,
      phone_number: row["phone_number"],
      email: row["email"],
    }
  end

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
