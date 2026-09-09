# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  audit_log                   :jsonb
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
#  index_batches_on_aasm_state                (aasm_state)
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
      transitions from: [ :fields_mapped, :failed ], to: :purchasing
    end

    # `failed` is a retryable state, not a terminal one: a stamps-only batch
    # that dies in label generation never enters `purchasing`, so without this
    # the retry hits `if may_mark_generating_labels?`, no-ops, and the batch
    # stays failed forever with its labels regenerated but never recorded.
    event :mark_generating_labels do
      transitions from: [ :fields_mapped, :purchasing, :failed ], to: :generating_labels
    end

    event :mark_processed do
      transitions from: [ :fields_mapped, :purchasing, :generating_labels, :failed ], to: :processed
      after do
        User::UpdateTasksJob.perform_later(user)
      end
    end

    event :mark_failed do
      transitions from: [ :purchasing, :generating_labels ], to: :failed
    end
  end

  self.inheritance_column = "type"
  belongs_to :user
  belongs_to :letter_queue, optional: true, class_name: "Letter::Queue"
  belongs_to :billing_profile, class_name: "BillingProfile", foreign_key: :hcb_payment_account_id, optional: true
  include Ledgerable
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

  def audit!(event, **data)
    log = (audit_log || [])
    log << { at: Time.current.iso8601, event: event }.merge(data)
    update_columns(audit_log: log)
  end

  def attach_pdf(pdf_data) = PdfAttachmentUtil.attach_pdf(pdf_data, self, :pdf_document)

  def total_cost
    raise NotImplementedError, "Subclasses must implement total_cost"
  end

  GREMLINS = [
    "‎",
    "​"
  ].join

  def csv_headers
    rows = CSV.parse(csv_data, headers: true)
    rows.headers
  end

  def run_map!
    rows = CSV.parse(csv_data, headers: true, converters: [ ->(s) { s&.strip&.delete(GREMLINS).presence } ])

    restricted_countries = Concurrent::Set.new

    # Phase 1: Build address attributes in parallel with correlation tokens
    items = Parallel.map(rows.each_with_index, in_threads: 8) do |row, i|
      begin
        next if row[field_mapping["first_name"]].blank?

        address_attrs = build_address_attributes(row)
        next unless address_attrs

        cc = address_attrs[:country]
        if usps_restricted?(cc)
          restricted_countries << cc
          next
        end

        { token: SecureRandom.uuid, row: row, attrs: address_attrs }
      rescue => e
        Rails.logger.error("Error processing row #{i} in batch #{id}: #{e.message}")
        raise
      end
    end.compact

    return mark_fields_mapped && save! if items.empty?

    now = Time.current
    address_attributes = items.map do |item|
      item[:attrs].merge(batch_id: id, import_token: item[:token], created_at: now, updated_at: now)
    end

    Address.insert_all!(address_attributes)

    tokens = items.map { |item| item[:token] }
    addresses_by_token = Address.where(import_token: tokens).index_by(&:import_token)

    items.each do |item|
      address = addresses_by_token.fetch(item[:token])
      ActiveRecord::Base.transaction do
        build_mapping(item[:row], address)
      end
    end

    Address.where(import_token: tokens).update_all(import_token: nil)

    mark_fields_mapped
    save!

    restricted_countries.to_a
  end

  def csv_sample_row
    rows = CSV.parse(csv_data, headers: true)
    rows.first
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

    resolved_country = country&.alpha2 || csv_country&.upcase

    {
      first_name: row[field_mapping["first_name"]],
      last_name: row[field_mapping["last_name"]],
      line_1: row[field_mapping["line_1"]],
      line_2: row[field_mapping["line_2"]],
      city: row[field_mapping["city"]],
      state: normalized_state,
      postal_code: postal_code,
      country: resolved_country,
      phone_number: row[field_mapping["phone_number"]],
      email: row[field_mapping["email"]]
    }
  end

  def build_mapping(row, address)
    # Base class just returns the address
    address
  end

  def usps_restricted?(country_code)
    return false if country_code.blank?
    restricted = Rails.configuration.country_restrictions.usps_restricted
    country_code.to_s.in?(restricted)
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
