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
class Letter::Batch < Batch
  self.inheritance_column = "type"
  # default_scope { where(type: 'letters') }
  has_many :letters, dependent: :destroy
  belongs_to :mailer_id, class_name: "USPS::MailerId", foreign_key: "letter_mailer_id_id", optional: true
  belongs_to :letter_return_address, class_name: "ReturnAddress", optional: true
  belongs_to :letter_queue, :class_name => "Letter::Queue", optional: true

  # Add ActiveStorage attachment for the batch label PDF
  has_one_attached :pdf_label

  # Add batch-level letter specifications
  attribute :letter_height, :decimal
  attribute :letter_width, :decimal
  attribute :letter_weight, :decimal
  attribute :letter_processing_category, :integer
  attribute :user_facing_title, :string
  attribute :letter_return_address_name, :string
  attribute :letter_queue_id, :integer
  attr_accessor :template, :template_cycle
  attribute :letter_mailing_date, :date

  validates :letter_height, :letter_width, :letter_weight, presence: true, numericality: { greater_than: 0 }
  validates :mailer_id, presence: true
  validates :letter_return_address, presence: true, on: :process
  validates :letter_mailing_date, presence: true, on: :process
  validate :mailing_date_not_in_past, if: -> { letter_mailing_date.present? }, on: :create
  validates :letter_processing_category, presence: true

  after_update :update_letter_tags, if: :saved_change_to_tags?

  def self.model_name
    Batch.model_name
  end

  # Directly attach a PDF to this batch
  def attach_pdf(pdf_data)
    io = StringIO.new(pdf_data)

    pdf_label.attach(
      io: io,
      filename: "label_batch_#{Time.now.to_i}.pdf",
      content_type: "application/pdf",
    )
  end

  def process!(options = {})
    return false unless fields_mapped?

    # Set postage types and user_facing_title for all letters based on options
    if options[:us_postage_type].present? || options[:intl_postage_type].present? || options[:user_facing_title].present?
      letters.each do |letter|
        letter.mailing_date = letter_mailing_date
        if letter.address.us?
          letter.postage_type = options[:us_postage_type] == "indicia" ? :indicia : :stamps
        else
          letter.postage_type = options[:intl_postage_type] == "indicia" ? :indicia : :stamps
        end
        letter.user_facing_title = options[:user_facing_title] if options[:user_facing_title].present?
        letter.save!
      end
    end

    # Purchase indicia for all letters if needed
    if options[:payment_account].present? &&
       (options[:us_postage_type] == "indicia" || options[:intl_postage_type] == "indicia")
      # Check if there are sufficient funds before processing
      indicia_cost = letters.includes(:address).sum do |letter|
        if letter.postage_type == "indicia"
          if letter.address.us?
            USPS::PricingEngine.metered_price(
              letter.processing_category,
              letter.weight,
              letter.non_machinable
            )
          else
            flirted = letter.flirt
            USPS::PricingEngine.metered_price(
              flirted[:processing_category],
              flirted[:weight],
              flirted[:non_machinable]
            )
          end
        else
          0
        end
      end

      # unless options[:payment_account].check_funds_available(indicia_cost)
      #   raise "...we're out of money (ask Nora to put at least #{ActiveSupport::NumberHelper.number_to_currency(indicia_cost)} in the #{options[:payment_account].display_name} account!)"
      # end

      purchase_batch_indicia(options[:payment_account])
    end

    # Generate PDF labels with the provided options
    generate_labels(options)

    mark_processed!
  end

  # Purchase indicia for all letters in the batch using a single payment token
  def purchase_batch_indicia(payment_account)
    # Create a single payment token for the entire batch
    payment_token = payment_account.create_payment_token

    # Preload associations to avoid N+1 queries
    letters.includes(:address).each do |letter|
      next unless letter.postage_type == "indicia" && letter.usps_indicium.nil?

      # Create and purchase indicia for each letter using the same payment token
      indicium = USPS::Indicium.new(
        letter: letter,
        payment_account: payment_account,
        mailing_date: letter_mailing_date,
      )
      indicium.buy!(payment_token)
    end
  end

  def total_cost
    postage_cost
  end

  def postage_cost
    # Preload associations to avoid N+1 queries
    letters.includes(:address, :usps_indicium).sum do |letter|
      if letter.postage_type == "indicia"
        if letter.usps_indicium.present?
          # Use actual indicia price if indicia are bought
          letter.usps_indicium.postage + letter.usps_indicium.fees
        elsif letter.address.us?
          # For US mail without bought indicia, use metered price
          USPS::PricingEngine.metered_price(
            letter.processing_category,
            letter.weight,
            letter.non_machinable
          )
        else
          # For international mail without bought indicia, use FLIRT-ed price
          flirted = letter.flirt
          USPS::PricingEngine.metered_price(
            flirted[:processing_category],
            flirted[:weight],
            flirted[:non_machinable]
          )
        end
      else
        # For stamps, use stamp price for US and desired price for international
        if letter.address.us?
          USPS::PricingEngine.domestic_stamp_price(
            letter.processing_category,
            letter.weight,
            letter.non_machinable
          )
        else
          USPS::PricingEngine.fcmi_price(
            letter.processing_category,
            letter.weight,
            letter.address.country
          )
        end
      end
    end
  end

  def postage_cost_difference(us_postage_type: nil, intl_postage_type: nil)
    # Preload associations to avoid N+1 queries
    letters.includes(:address, :usps_indicium).each_with_object({ us: 0, intl: 0 }) do |letter, differences|
      # Determine what postage type this letter would use
      effective_postage_type = if letter.address.us?
          us_postage_type || letter.postage_type
        else
          intl_postage_type || letter.postage_type
        end

      # Skip if not switching to indicia
      next unless effective_postage_type == "indicia"

      if letter.address.us?
        # For US mail:
        # Retail price is stamp_price
        retail_price = USPS::PricingEngine.domestic_stamp_price(
          letter.processing_category,
          letter.weight,
          letter.non_machinable
        )

        # Indicia price is metered_price
        indicia_price = if letter.usps_indicium.present?
            letter.usps_indicium.postage
          else
            USPS::PricingEngine.metered_price(
              letter.processing_category,
              letter.weight,
              letter.non_machinable
            )
          end

        # Difference should be negative (savings)
        differences[:us] += indicia_price - retail_price
      else
        # For international mail:
        # Retail price is desired_price
        retail_price = USPS::PricingEngine.fcmi_price(
          letter.processing_category,
          letter.weight,
          letter.address.country
        )

        # Indicia price is flirted price (higher than retail)
        indicia_price = if letter.usps_indicium.present?
            letter.usps_indicium.postage
          else
            # Use flirt to get the closest US price that's higher than the FCMI rate
            flirted = letter.flirt
            USPS::PricingEngine.metered_price(
              flirted[:processing_category],
              flirted[:weight],
              flirted[:non_machinable]
            )
          end

        # Difference should be positive (additional cost)
        differences[:intl] += indicia_price - retail_price
      end
    end
  end

  def mailing_date_not_in_past
    if letter_mailing_date < Date.current
      errors.add(:letter_mailing_date, "cannot be in the past")
    end
  end

  def default_mailing_date
    now = Time.current.in_time_zone("Eastern Time (US & Canada)")
    today = now.to_date

    # If it's before 4PM EST on a business day, default to today
    if now.hour < 16 && today.on_weekday?
      today
    else
      # Otherwise, default to next business day
      next_business_day = today
      loop do
        next_business_day += 1
        break if next_business_day.on_weekday?
      end
      next_business_day
    end
  end

  private

  def update_letter_tags
    letters.update_all(tags: tags)
  end

  def address_fields
    # Only include address fields and rubber_stamps for letter mapping
    ["rubber_stamps"]
  end

  def build_mapping(row, address)
    # Build letter with batch-level specs and extra data
    letters.build(
      height: letter_height,
      width: letter_width,
      weight: letter_weight,
      processing_category: letter_processing_category,
      recipient_email: row&.dig(field_mapping["email"]),
      address: address,
      usps_mailer_id: mailer_id,
      return_address: letter_return_address,
      return_address_name: letter_return_address_name,
      rubber_stamps: row&.dig(field_mapping["rubber_stamps"]),
      tags: tags,
      user: user,
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
