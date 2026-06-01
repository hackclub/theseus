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

  def process!(options = {})
    return false unless fields_mapped?

    # Set postage types and user_facing_title for all letters based on options
    if options[:us_postage_type].present? || options[:intl_postage_type].present? || options[:user_facing_title].present?
      letters.each do |letter|
        letter.mailing_date = letter_mailing_date
        if letter.return_address.us?
          # For US return addresses, use the US postage type
          letter.postage_type = options[:us_postage_type]
        else
          # For non-US return addresses, must use international origin
          letter.postage_type = "international_origin"
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

      unless options[:payment_account].check_funds_available(indicia_cost)
        raise "...we're out of money (ask Nora to put at least #{ActiveSupport::NumberHelper.number_to_currency(indicia_cost)} in the #{options[:payment_account].display_name} account!)"
      end

      purchase_batch_indicia(options[:payment_account], hcb_payment_account: options[:hcb_payment_account])
    end

    # Generate PDF labels with the provided options
    generate_labels(options)

    mark_processed!
  end

  def regenerate_labels!(options = {})
    labels_pdf.purge
    generate_labels(options)
  end

  def purchase_batch_indicia(usps_payment_account, hcb_payment_account:)
    raise ArgumentError, "HCB payment account is required to purchase indicia" if hcb_payment_account.nil?
    raise ArgumentError, "USPS payment account is required to purchase indicia" if usps_payment_account.nil?

    letters_needing_indicia = letters.select do |letter|
      letter.postage_type == "indicia" && letter.usps_indicium.nil?
    end

    return if letters_needing_indicia.empty?

    total_cost_cents = letters_needing_indicia.sum do |letter|
      (letter.postage * 100).ceil
    end

    letter_count = letters_needing_indicia.count { |l| l.processing_category == "letter" }
    flat_count = letters_needing_indicia.count { |l| l.processing_category == "flat" }
    batch_description = [
      ("#{letter_count} #{"letter".pluralize(letter_count)}" if letter_count > 0),
      ("#{flat_count} #{"flat".pluralize(flat_count)}" if flat_count > 0),
    ].compact.join(" and ")

    transfer_service = HCB::TransferService.new(
      hcb_payment_account: hcb_payment_account,
      amount_cents: total_cost_cents,
      name: "Batch postage for #{public_id} (#{letters_needing_indicia.count} letters) #{Rails.application.routes.url_helpers.letter_batch_path(self)}",
      memo: "[theseus] postage for a batch of #{batch_description}",
    )
    transfer = transfer_service.call
    unless transfer
      raise StandardError, transfer_service.errors.join(", ")
    end

    begin
      payment_token = usps_payment_account.create_payment_token
    rescue => e
      HCB::PaymentAccount.refund_to_organization!(
        organization_id: hcb_payment_account.organization_id,
        amount_cents: total_cost_cents,
        name: "Refund for batch #{public_id} #{Rails.application.routes.url_helpers.letter_batch_path(self)}",
        memo: "[theseus] postage refund for a batch of #{batch_description}",
      )
      raise e
    end

    ActiveRecord::Base.transaction do
      update!(
        hcb_payment_account: hcb_payment_account,
        hcb_transfer_id: transfer.id,
      )

      letters_needing_indicia.each do |letter|
        indicium = USPS::Indicium.create!(
          letter: letter,
          payment_account: usps_payment_account,
          hcb_payment_account: hcb_payment_account,
          mailing_date: letter_mailing_date,
        )
        begin
          indicium.buy!(payment_token)
        rescue => e
          if indicium.raw_json_response.present?
            Sentry.capture_exception(e, level: :fatal, tags: { money: true, critical: true },
              extra: { letter_id: letter.id, batch_id: id, response: indicium.raw_json_response })
          end
          raise e
        end
      end
    end
  end

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

  private

  def update_letter_tags
    letters.update_all(tags: tags)
  end

  def address_fields
    # Only include address fields and rubber_stamps for letter mapping
    ["rubber_stamps"]
  end

  def build_mapping(row, address)
    letters.build(
      height: letter_height,
      width: letter_width,
      weight: letter_weight,
      processing_category: letter_processing_category,
      recipient_email: row["email"],
      address: address,
      usps_mailer_id: mailer_id,
      return_address: letter_return_address,
      return_address_name: letter_return_address_name,
      rubber_stamps: row["rubber_stamps"],
      tags: tags,
      user: user,
    )
  end

  def generate_labels(options = {})
    return unless letters.any?

    # Preload associations to avoid N+1 queries
    preloaded_letters = letters.order(:id).includes(:address, :usps_mailer_id, :usps_indicium, :return_address)

    # Build options for label generation
    label_options = {}

    # Add template information
    if template_cycle.present?
      label_options[:template_cycle] = template_cycle
    elsif template.present?
      label_options[:template] = template
    end

    # Use the SnailMail service to generate labels
    pdf = SnailMail::PhlexService.generate_batch_labels(
      preloaded_letters,
      label_options.merge(options)
    )

    # Directly attach the PDF to this batch
    attach_pdf(pdf.render)

    # Return the PDF
    pdf
  end
end
