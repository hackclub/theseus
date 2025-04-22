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
  taggable_array :tags

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

  def attach_pdf(pdf_data)
    PdfAttachmentUtil.attach_pdf(pdf_data, self, :pdf_document)
  end

  def total_cost
    raise NotImplementedError, "Subclasses must implement total_cost"
  end

  GREMLINS = [
    "‎",
    "​"
  ].join
  def run_map!
    csv_content = csv.download
    CSV.parse(csv_content, headers: true, encoding: "UTF-8", converters: [ ->(s) { s&.strip&.delete(GREMLINS).presence } ])&.each_with_index do |row, i|
    begin
        build_mapping(row)
      # figure out how to rescue this
    end
    end
    mark_fields_mapped
    save!
  end


  private

  def build_address(row)
    csv_country = row[field_mapping["country"]]

    country = FrickinCountryNames.find_country!(csv_country)

    postal_code = row[field_mapping["postal_code"]]

    if country.alpha2 == "US" && postal_code.length < 5
      postal_code = postal_code.rjust(5, "0")
    end

    state = FrickinCountryNames.normalize_state(country, row[field_mapping["state"]])

    addresses.build(
      first_name: row[field_mapping["first_name"]],
      last_name: row[field_mapping["last_name"]],
      line_1: row[field_mapping["line_1"]],
      line_2: row[field_mapping["line_2"]],
      city: row[field_mapping["city"]],
      state: state,
      postal_code: postal_code,
      country: country.alpha2,
      phone_number: row[field_mapping["phone_number"]],
      email: row[field_mapping["email"]],
      )
  end
  def build_mapping(row)
    build_address(row)
  end
end
