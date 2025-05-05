# == Schema Information
#
# Table name: warehouse_orders
#
#  id                      :bigint           not null, primary key
#  aasm_state              :string
#  canceled_at             :datetime
#  carrier                 :string
#  contents_cost           :decimal(10, 2)
#  dispatched_at           :datetime
#  idempotency_key         :string
#  internal_notes          :text
#  labor_cost              :decimal(10, 2)
#  mailed_at               :datetime
#  metadata                :jsonb
#  notify_on_dispatch      :boolean
#  postage_cost            :decimal(, )
#  recipient_email         :string
#  service                 :string
#  surprise                :boolean
#  tags                    :citext           default([]), is an Array
#  tracking_number         :string
#  user_facing_description :string
#  user_facing_title       :string
#  weight                  :decimal(, )
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  address_id              :bigint           not null
#  batch_id                :bigint
#  hc_id                   :string
#  purpose_code_id         :bigint
#  source_tag_id           :bigint           not null
#  template_id             :bigint
#  user_id                 :bigint           not null
#  zenventory_id           :integer
#
# Indexes
#
#  index_warehouse_orders_on_address_id       (address_id)
#  index_warehouse_orders_on_batch_id         (batch_id)
#  index_warehouse_orders_on_hc_id            (hc_id)
#  index_warehouse_orders_on_idempotency_key  (idempotency_key) UNIQUE
#  index_warehouse_orders_on_purpose_code_id  (purpose_code_id)
#  index_warehouse_orders_on_source_tag_id    (source_tag_id)
#  index_warehouse_orders_on_tags             (tags) USING gin
#  index_warehouse_orders_on_template_id      (template_id)
#  index_warehouse_orders_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (purpose_code_id => warehouse_purpose_codes.id)
#  fk_rails_...  (source_tag_id => source_tags.id)
#  fk_rails_...  (template_id => warehouse_templates.id)
#  fk_rails_...  (user_id => users.id)
#
class Warehouse::Order < ApplicationRecord
  include AASM
  include HasAddress
  include CanBeBatched
  include PublicIdentifiable
  set_public_id_prefix "pkg"

  belongs_to :template, class_name: "Warehouse::Template", optional: true
  belongs_to :user
  belongs_to :source_tag

  validates :line_items, presence: true
  validates :recipient_email, presence: true
  validate :can_mail_parcels_to_country

  after_create :set_hc_id
  before_save :update_costs

  include HasWarehouseLineItems
  include HasTableSync
  include HasZenventoryUrl
  include Taggable

  has_table_sync ENV["AIRTABLE_THESEUS_BASE"],
                 ENV["AIRTABLE_WAREHOUSE_REQUESTS_TABLE"],
                 {
                   id: :hc_id,
                   state: :aasm_state,
                   recipient: :recipient_email,
                   contents: :generate_order_items,
                   created_at: :created_at,
                   updated_at: :updated_at,
                   zenventory_id: :zenventory_id,
                   user_facing_title: :user_facing_title,
                   tracking_number: :tracking_number,
                   carrier: :carrier,
                   service: :service,
                   mailed_at: :mailed_at,
                   labor_cost: :labor_cost,
                   postage_cost: :postage_cost
                 }

  has_zenventory_url "https://app.zenventory.com/orders/edit-order/%s", :zenventory_id

  def shipping_address_attributes
    {
      name: address.name_line,
      line1: address.line_1,
      line2: address.line_2,
      city: address.city,
      state: address.state,
      zip: address.postal_code,
      countryCode: address.country,
      phone: address.phone_number
    }.compact_blank
  end

  def customer_attributes
    {
      name: address.first_name,
      surname: address.last_name || "​",
      email: recipient_email
    }.compact_blank
  end

  def cancel!(reason)
    transaction do
      mark_canceled!
      Zenventory.cancel_customer_order(zenventory_id, reason)
    end
  end

  def dispatch!
    ActiveRecord::Base.transaction do
      raise AASM::InvalidTransition, "wrong state" unless may_mark_dispatched?
      order = Zenventory.create_customer_order(
        {
          orderNumber: "hack.club/#{hc_id}",
          customer: customer_attributes,
          shippingAddress: shipping_address_attributes,
          billingAddress: { sameAsShipping: true },
          items: generate_order_items
        }
      )
      mark_dispatched!(order[:id])
    end

    if notify_on_dispatch?
      Warehouse::OrderMailer.with(order: self).order_created.deliver_later
    end
  end

  def zenv_attributes_changed?
    return true if recipient_email_changed?
    return true if address&.changed?
    return true if line_items.any?(&:marked_for_destruction?) ||
                  line_items.any?(&:new_record?) ||
                  line_items.any?(&:changed?)
    false
  end

  before_update { |rec| try_zenventory_update! if rec.zenv_attributes_changed? && !rec.draft? }

  def try_zenventory_update!
    if mailed?
      errors.add(:base, "can't edit an order that's already been shipped!")
      throw(:abort)
    end
    if canceled?
      errors.add(:base, "can't edit an order that's canceled!")
      throw(:abort)
    end
    begin
      update_hash = {
        customer: customer_attributes,
        shippingAddress: shipping_address_attributes,
        billingAddress: { sameAsShipping: true },
        items: generate_order_items_for_update
      }.compact_blank
      Zenventory.update_customer_order(zenventory_id, update_hash) unless update_hash.empty?
    rescue Zenventory::ZenventoryError => e
      errors.add(:base, "couldn't edit order, Zenventory said: #{e.message}")
      throw(:abort)
    end
  end

  def self.from_template(template, attributes)
    new(
      attributes.merge(
        template: template,
        source_tag: template.source_tag,
      )
    )
  end

  def initialize(attributes = {})
    super
    if attributes&.[](:template)
      template.line_items.each do |template_line_item|
        line_items.build(
          sku: template_line_item.sku,
          quantity: template_line_item.quantity
        )
      end
    end
  end

  HUMANIZED_STATES = {
    draft: "Draft",
    dispatched: "Sent to warehouse",
    mailed: "Shipped!",
    errored: "Errored?",
    canceled: "Canceled"
  }

  def humanized_state
    HUMANIZED_STATES[aasm_state.to_sym]
  end

  aasm timestamps: true do
    state :draft, initial: true
    state :dispatched
    state :mailed
    state :errored
    state :canceled

    event :mark_dispatched do
      transitions from: :draft, to: :dispatched
      after do |zenventory_id|
        update!(zenventory_id:)
      end
    end

    event :mark_mailed do
      transitions from: :dispatched, to: :mailed
    end

    event :mark_canceled do
      transitions from: :dispatched, to: :canceled
    end
  end

  def tracking_format
    @tracking_format ||= Tracking.get_format_by_zenv_info(carrier:, service:)
  end

  def tracking_url
    Tracking.tracking_url_for(tracking_format, tracking_number)
  end

  def might_be_slow?
    %i[asendia usps].include?(tracking_format)
  end

  def pretty_via
    case tracking_format
    when :usps
      "USPS"
    when :asendia
      "Asendia"
    when :ups
      "UPS #{service}"
    else
      "#{carrier} #{service}"
    end
  end

  def generate_order_items
    line_items.map do |line_item|
      {
        sku: line_item.sku.sku,
        price: line_item.sku.declared_unit_cost,
        quantity: line_item.quantity
      }
    end
  end

  # nora: entirely v*becoded because i can't be fucked
  def generate_order_items_for_update
    # Check if we need to fetch existing order details from Zenventory
    has_deletions = line_items.any?(&:marked_for_destruction?)
    has_modifications = line_items.reject(&:marked_for_destruction?).any? { |li| li.changed? }

    # Only fetch from Zenventory if we need IDs for updates or deletions
    zenventory_item_map = {}
    if has_deletions || has_modifications
      # Fetch current order from Zenventory to get line item IDs
      zenventory_order = Zenventory.get_customer_order(zenventory_id)
      zenventory_items = zenventory_order[:items] || []

      # Use index_by to create a lookup hash of existing Zenventory line items by SKU
      zenventory_item_map = zenventory_items.index_by { |item| item[:sku] }
    end

    items_to_update = []

    # Process items marked for deletion
    if has_deletions
      line_items.select(&:marked_for_destruction?).each do |line_item|
        zenv_item = zenventory_item_map[line_item.sku.sku]
        next unless zenv_item # Skip if we can't find the item in Zenventory

        items_to_update << create_item_hash(line_item, zenv_item[:id], 0) # Set quantity to 0 for deletion
      end
    end

    # Process new and modified items
    line_items.reject(&:marked_for_destruction?).each do |line_item|
      if line_item.new_record?
        # New line item - don't include ID
        items_to_update << create_item_hash(line_item)
      elsif line_item.changed?
        # Modified line item - include ID if available
        zenv_item = zenventory_item_map[line_item.sku.sku]
        items_to_update << create_item_hash(line_item, zenv_item&.dig(:id))
      end
    end

    items_to_update
  end

  # Helper method just for updates
  private def create_item_hash(line_item, item_id = nil, quantity = nil)
    item_hash = {
      sku: line_item.sku.sku,
      price: line_item.sku.declared_unit_cost,
      quantity: quantity || line_item.quantity
    }

    # Only include ID if one was provided
    item_hash[:id] = item_id if item_id

    item_hash
  end

  def total_cost
    [contents_cost, labor_cost, postage_cost].compact_blank.sum
  end
  def to_param
    hc_id
  end

  private
  def set_hc_id
    update_column(:hc_id, public_id)
  end

  def update_costs
    # Ensure line items are loaded and include their SKUs
    line_items.includes(:sku).load
    self.labor_cost = labor_cost
    self.contents_cost = contents_actual_cost_to_hc
  end

  def can_mail_parcels_to_country
    errors.add(:base, :cant_mail, message: "We can't currently ship to #{ISO3166::Country[address.country]&.common_name || address.country} from the warehouse.") if %i[IR PS CU KP RU].include? address.country&.to_sym
  end

  def inherit_batch_tags
    return unless batch.present?
    self.tags = (tags + batch.tags).uniq
  end
end
