# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  audit_log                   :jsonb
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
class Warehouse::Batch < Batch
  belongs_to :warehouse_template, class_name: "Warehouse::Template"

  has_many :orders, class_name: "Warehouse::Order"

  def self.model_name = Batch.model_name

  def process!(options = {})
    return false unless fields_mapped?

    # Create orders for each address
    addresses.each do |address|
      Warehouse::Order.from_template(
        warehouse_template,
        batch: self,
        recipient_email: address.email,
        address: address,
        user: user,
        idempotency_key: "batch_#{id}_address_#{address.id}",
        user_facing_title: warehouse_user_facing_title,
        tags: tags,
      ).save!
    end

    # Dispatch all orders
    orders.each do |order|
      order.dispatch!
    end

    mark_processed!
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

  def process_with_zenventory!(options = {})
    return false unless fields_mapped?

    # Create orders for each address
    addresses.each do |address|
      begin
        Zenventory.create_customer_order(update_hash)
      rescue Zenventory::ZenventoryError => e
        event_id = Sentry.capture_exception(e)&.event_id
        errors.add(:base, "couldn't create order, Zenventory said: #{e.message} (error: #{event_id})")
        throw(:abort)
      end
    end

    # Dispatch all orders
    orders.each do |order|
      order.dispatch!
    end

    mark_processed!
  end
end
