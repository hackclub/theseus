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
class Letter::Batch < Batch
  def self.policy_class = Letter::BatchPolicy

  include PgSearch::Model

  pg_search_scope :search,
    against: %i[tags letter_return_address_name],
    associated_against: {
      csv_blob: %i[filename],
      user: %i[email username],
      letter_queue: %i[name]
    },
    using: {
      tsearch: { prefix: true }
    }

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
    priced_letters.sum do |letter|
      priced(letter) { letter.postage_type == "indicia" ? indicia_price(letter, non_machinable) : letter.postage_for(postage_type: letter.postage_type || "stamps", non_machinable: non_machinable) } || 0
    end
  end

  alias_method :total_cost, :postage_cost

  # What USPS actually took, read off the indicia rather than the letter's
  # `indicia_state`. `postage` is only ever persisted by the trailing `save!`
  # in USPS::Indicium#buy!, i.e. after USPS sold us postage, so a non-null
  # postage IS the purchase. `indicia_state` is written afterwards and only by
  # BatchProcessJob, so it's a strict subset: main-era letters (and anything
  # bought through USPS::IndiciumPurchase) have a real indicium and a nil
  # state. Filtering on the state made those read as $0 spent, which showed up
  # as a full-batch "Overpaid" the moment the charge was backfilled.
  def actual_spent_cents
    (letters.joins(:usps_indicium)
      .where.not(usps_indicia: { postage: nil })
      .sum("COALESCE(usps_indicia.postage, 0) + COALESCE(usps_indicia.fees, 0)") * 100).ceil
  end

  def indicia_charges = ledger_entries.indicia.charges.live

  # Settled postage money, net of refunds, that USPS hasn't consumed yet.
  # Positive after processing means we overcharged; the job treats it as
  # prepaid when re-running.
  def prepaid_cents = indicia_charges.settled.sum(&:net_cents) - actual_spent_cents

  # The newest settled charge with money left on it: where a refund comes from.
  def refundable_charge = indicia_charges.settled.order(id: :desc).detect { |c| c.net_cents.positive? }

  # Savings (negative) or cost (positive) of indicia vs. retail stamps, per region.
  def postage_cost_difference(us_postage_type: nil, intl_postage_type: nil, non_machinable: nil)
    priced_letters.each_with_object({ us: 0, intl: 0 }) do |letter, diff|
      region = letter.address.us? ? :us : :intl
      type = (region == :us ? us_postage_type : intl_postage_type) || letter.postage_type
      next unless type == "indicia"
      diff[region] += priced(letter) { indicia_price(letter, non_machinable) - letter.postage_for(postage_type: "stamps", non_machinable: non_machinable) } || 0

    end
  end

  # What processing will charge. Pass `letters:` once they're configured
  # (BatchProcessJob), or the form's options beforehand.
  def billing_lines(letters: nil, us_postage_type: nil, intl_postage_type: nil, non_machinable: nil)
    cents = 0
    n = 0
    (letters || priced_letters).each do |letter|
      type = letters ? letter.postage_type : (letter.address&.us? ? us_postage_type : (intl_postage_type || "international_origin"))
      next unless type == "indicia" && letter.usps_indicium&.postage.blank?
      price = letters ? letter.postage : priced(letter) { letter.postage_for(postage_type: "indicia", non_machinable: non_machinable) }
      next if price.nil?
      n += 1
      cents += (price.to_d * 100).ceil
    end
    return [] if n.zero?
    [ Billing::Quote::Line.new(category: :indicia, label: "estimated postage for #{n} #{"letter".pluralize(n)} in #{public_id}", when: :now, amount_cents: cents, count: n) ]
  end

  private def priced_letters = letters.includes(:address, :usps_indicium)

  private def indicia_price(letter, non_machinable)
    letter.usps_indicium&.postage.present? ? letter.usps_indicium.cost : letter.postage_for(postage_type: "indicia", non_machinable: non_machinable)
  end

  private def priced(letter)
    yield
  rescue USPS::USPSError => e
    Rails.logger.warn("Skipping letter #{letter.id} (#{letter.address&.country}) in pricing: #{e.message}")
    nil
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
    pdf_label.purge
    generate_labels(options)
  end

  # Propagate batch attributes to letters after update.
  # Only propagates sizing/mailing attrs if the batch hasn't been processed yet.
  def propagate_to_letters!
    if may_mark_processed?
      letters.update_all(
        height: letter_height,
        width: letter_width,
        weight: letter_weight,
        processing_category: letter_processing_category,
        mailing_date: letter_mailing_date,
        usps_mailer_id_id: letter_mailer_id_id,
        return_address_id: letter_return_address_id,
        return_address_name: letter_return_address_name,
      )
    end
    letters.update_all(tags: tags, user_facing_title: user_facing_title)
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
