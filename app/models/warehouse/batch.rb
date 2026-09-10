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
  # Orders keep origin_batch_id even if they're later detached from the batch,
  # which is what makes process! safe to re-run.
  has_many :originated_orders, class_name: "Warehouse::Order", foreign_key: :origin_batch_id, inverse_of: :origin_batch

  def self.model_name = Batch.model_name

  # Warehouse batches only ever come from a CSV; there's no queue to feed them.
  validate on: :create do
    errors.add(:csv, "must be uploaded") unless csv.attached?
  end

  # how many bad rows we'll name before giving up and just counting them
  PREFLIGHT_ERROR_LIMIT = 25

  # Re-runnable. A dispatch that blows up on row k leaves the batch in
  # fields_mapped with the first k orders already created and sent, so every
  # phase here reconciles against what's already on disk instead of assuming a
  # clean slate.
  def process!(options = {})
    unless fields_mapped?
      errors.add(:base, "This batch can't be processed while it's #{aasm_state.humanize.downcase}.")
      return false
    end

    unless addresses.exists?
      errors.add(:base, "This batch has no addresses to process.")
      return false
    end

    if Flipper.enabled?(:require_billing_profile_2026_09_08) && billing_profile.blank?
      errors.add(:base, "Pick a billing profile before processing this batch.")
      return false
    end

    unless claim_for_dispatch!
      errors.add(:base, "This batch is already being processed.")
      return false
    end

    begin
      undispatched = reconcile_orders!
      if undispatched.nil?
        release_dispatch_claim!
        return false
      end

      undispatched.each(&:dispatch!)

      # One charge for the whole batch's labor. `unclaimed` makes this idempotent:
      # entries a previous run already claimed belong to a transfer and won't be
      # picked up again. If a transfer is in flight the entries stay unclaimed and
      # the sweep batches them.
      if billing_profile.present?
        Billing.charge!(
          LedgerEntry.unclaimed.charges.labor.where(ledgerable: originated_orders),
          name: "Labor for batch #{public_id}",
        )
      end
    rescue StandardError
      release_dispatch_claim!
      raise
    end

    mark_processed!
  end

  # dispatch! POSTs to Zenventory before it takes its own row lock, so two
  # concurrent process! calls would create the same order in the warehouse
  # twice. Moving the batch out of fields_mapped with a conditional UPDATE lets
  # exactly one caller past, and unlike a row lock it doesn't hold a transaction
  # open across the HTTP round trips.
  DISPATCH_CLAIM_STATE = "purchasing"

  private def claim_for_dispatch!
    claimed = self.class.where(id: id, aasm_state: "fields_mapped")
                  .update_all(aasm_state: DISPATCH_CLAIM_STATE, updated_at: Time.current)
    return false if claimed.zero?

    reload
    true
  end

  private def release_dispatch_claim!
    self.class.where(id: id, aasm_state: DISPATCH_CLAIM_STATE)
        .update_all(aasm_state: "fields_mapped", updated_at: Time.current)
    reload
  end

  # Brings the batch's orders in line with its addresses and returns the ones
  # still waiting to go to the warehouse, or nil if the batch doesn't validate.
  #
  # Build every missing order first and validate the lot. Saving as we go would
  # leave a half-created batch behind the moment one row is missing a phone
  # number for customs, and the good half is already on its way to the warehouse
  # by then.
  #
  # The row lock stops two clicks on "Process" from both deciding the same
  # address needs a new order. It is released before we dispatch: dispatch!
  # talks to Zenventory over HTTP, and holding the transaction open across that
  # would mean one bad order rolls back the orders we already created *and*
  # dispatched — leaving live Zenventory orders with no Theseus rows behind
  # them, and a retry that rebuilds them under fresh hc_ids and ships everything
  # twice.
  private def reconcile_orders!
    with_lock do
      next nil unless aasm_state == DISPATCH_CLAIM_STATE

      # origin_batch_id sticks to an order for life, so it's the honest answer
      # to "did this batch already produce an order for this address?" — and it
      # lines up 1:1 with the unique idempotency_key we'd otherwise collide on.
      existing = originated_orders.to_a
      claimed = existing.map(&:address_id).to_set
      new_orders = addresses.reject { |address| claimed.include?(address.id) }
                            .map { |address| build_order_for(address) }

      next nil unless preflight(new_orders)

      new_orders.each(&:save!)

      (existing + new_orders).select(&:draft?)
    end
  end

  # Surfaces every unmailable row at once instead of blowing up on the first one.
  def preflight(new_orders = addresses.map { |address| build_order_for(address) })
    problems = new_orders.filter_map do |order|
      messages = mailability_errors(order)
      [ order, messages ] if messages.any?
    end
    return true if problems.empty?

    problems.first(PREFLIGHT_ERROR_LIMIT).each do |order, messages|
      errors.add(:base, "#{order.address.name_line}: #{messages.to_sentence}")
    end
    if problems.size > PREFLIGHT_ERROR_LIMIT
      errors.add(:base, "...and #{problems.size - PREFLIGHT_ERROR_LIMIT} more rows with problems.")
    end

    false
  end

  # The billing profile is picked on the process page, which is the page this
  # runs for: holding its absence against every row would hide the form that
  # sets it. process! refuses without one instead.
  private def mailability_errors(order)
    order.valid?
    order.errors.reject { |error| error.attribute == :billing_profile }.map(&:full_message)
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

  def billing_lines
    n = addresses.count
    return [] if n.zero?
    [
      Billing::Quote::Line.new(category: :labor, label: "labor for #{n} #{"order".pluralize(n)} in #{public_id}", when: :now, amount_cents: (warehouse_template.labor_cost.to_d * 100).ceil * n, count: n),
      Billing::Quote::Line.new(category: :postage, label: "postage for #{n} #{"order".pluralize(n)}, at cost, as they ship", when: :later, count: n)
    ]
  end

  def contents_cost = warehouse_template.contents_actual_cost_to_hc * addresses.count

  def labor_cost = warehouse_template.labor_cost * addresses.count

  def postage_cost = orders.sum(:postage_cost)

  def total_cost = contents_cost + labor_cost + postage_cost

  def update_associated_tags = orders.update_all(tags:)
end
