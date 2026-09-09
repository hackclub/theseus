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
class Warehouse::Batch < Batch
  belongs_to :warehouse_template, class_name: "Warehouse::Template"

  include PgSearch::Model

  pg_search_scope :search,
    against: %i[tags warehouse_user_facing_title],
    associated_against: {
      csv_blob: %i[filename],
      user: %i[email username],
      warehouse_template: %i[name]
    },
    using: {
      tsearch: { prefix: true }
    }

  has_many :orders, class_name: "Warehouse::Order"

  def self.model_name = Batch.model_name

  # how many bad rows we'll name before giving up and just counting them
  PREFLIGHT_ERROR_LIMIT = 25

  def process!(options = {})
    return false unless fields_mapped?

    # Build every order first and validate the lot. Saving as we go would leave a
    # half-created batch behind the moment one row is missing a phone number for
    # customs, and the good half is already on its way to the warehouse by then.
    new_orders = addresses.map { |address| build_order_for(address) }
    return false unless preflight(new_orders)

    transaction { new_orders.each(&:save!) }

    transaction { new_orders.each(&:save!) }

    new_orders.each(&:dispatch!)

    # One charge for the whole batch's labor. If a transfer is in flight the
    # entries stay unclaimed and the sweep batches them.
    if billing_profile.present?
      Billing.charge!(
        LedgerEntry.unclaimed.charges.labor.where(ledgerable: orders),
        name: "Labor for batch #{public_id}",
      )
    end

    mark_processed!
  end

  # Surfaces every unmailable row at once instead of blowing up on the first one.
  def preflight(new_orders = addresses.map { |address| build_order_for(address) })
    invalid = new_orders.reject(&:valid?)
    return true if invalid.empty?

    invalid.first(PREFLIGHT_ERROR_LIMIT).each do |order|
      errors.add(:base, "#{order.address.name_line}: #{order.errors.full_messages.to_sentence}")
    end
    if invalid.size > PREFLIGHT_ERROR_LIMIT
      errors.add(:base, "...and #{invalid.size - PREFLIGHT_ERROR_LIMIT} more rows with problems.")
    end

    false
  end

  private def build_order_for(address)
    Warehouse::Order.from_template(
      warehouse_template,
      batch: self,
      recipient_email: address.email,
      address: address,
      user: user,
      billing_profile: billing_profile,
      idempotency_key: "batch_#{id}_address_#{address.id}",
      user_facing_title: warehouse_user_facing_title,
      tags: tags,
    )
  end

  def build_mapping(row, address)
    # For warehouse batches, we just return the address
    # Orders will be created during processing
    address
  end

  def contents_cost = warehouse_template.contents_actual_cost_to_hc * addresses.count

  def labor_cost = warehouse_template.labor_cost * addresses.count

  def postage_cost = orders.sum(:postage_cost)

  def total_cost = contents_cost + labor_cost + postage_cost

  def update_associated_tags = orders.update_all(tags:)

end
