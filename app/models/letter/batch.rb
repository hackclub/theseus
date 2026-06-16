# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  field_mapping               :jsonb
#  hcb_transfer_amount_cents   :integer
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
class Letter::Batch < Batch
  def self.policy_class = Letter::BatchPolicy

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
  attr_accessor :template, :template_cycle, :non_machinable
  attribute :letter_mailing_date, :date

  validates :letter_height, :letter_width, :letter_weight, presence: true, numericality: { greater_than: 0 }
  validates :mailer_id, presence: true
  validates :letter_return_address, presence: true, on: :process
  validates :letter_mailing_date, presence: true, on: :process
  validate :mailing_date_not_in_past, if: -> { letter_mailing_date.present? }, on: :create
  validates :letter_processing_category, presence: true

  after_update :update_letter_tags, if: :saved_change_to_tags?

  def self.model_name = Batch.model_name

  # Directly attach a PDF to this batch
  def attach_pdf(pdf_data)
    io = StringIO.new(pdf_data)

    pdf_label.attach(
      io: io,
      filename: "label_batch_#{Time.now.to_i}.pdf",
      content_type: "application/pdf",
    )
  end

  # Processing is now handled by BatchProcessJob.
  # Use: BatchProcessJob.perform_later(batch.id) after setting process_options.

  def postage_cost(non_machinable: nil)
    # Preload associations to avoid N+1 queries
    letters.includes(:address, :usps_indicium).sum do |letter|
      effective_non_machinable = non_machinable.nil? ? letter.non_machinable : non_machinable

      if letter.postage_type == "indicia"
        if letter.usps_indicium.present?
          # Use actual indicia price if indicia are bought
          letter.usps_indicium.postage + letter.usps_indicium.fees
        elsif letter.address.us?
          # For US mail without bought indicia, use metered price
          USPS::PricingEngine.metered_price(
            letter.processing_category,
            letter.weight,
            effective_non_machinable
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
            effective_non_machinable
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

  alias_method :total_cost, :postage_cost

  def postage_cost_difference(us_postage_type: nil, intl_postage_type: nil, non_machinable: nil)
    # Preload associations to avoid N+1 queries
    letters.includes(:address, :usps_indicium).each_with_object({ us: 0, intl: 0 }) do |letter, differences|
      effective_non_machinable = non_machinable.nil? ? letter.non_machinable : non_machinable

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
          effective_non_machinable
        )

        # Indicia price is metered_price
        indicia_price = if letter.usps_indicium.present?
            letter.usps_indicium.postage
          else
            USPS::PricingEngine.metered_price(
              letter.processing_category,
              letter.weight,
              effective_non_machinable
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

  def generate_labels(options = {})
    return unless letters.any?

    preloaded_letters = letters.order(:id).includes(:address, :usps_mailer_id, :usps_indicium, :return_address)

    label_options = {}
    if template_cycle.present?
      label_options[:template_cycle] = template_cycle
    elsif template.present?
      label_options[:template] = template
    end

    pdf = SnailMail::PhlexService.generate_batch_labels(
      preloaded_letters,
      label_options.merge(options)
    )

    attach_pdf(pdf.render)
    pdf
  end

  def regenerate_labels!(options = {})
    labels_pdf.purge
    generate_labels(options)
  end

  private

  def update_letter_tags
    letters.update_all(tags: tags)
  end

  def address_fields
    # Only include address fields and rubber_stamps for letter mapping
    ["rubber_stamps"]
  end
end
