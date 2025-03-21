# == Schema Information
#
# Table name: warehouse_orders
#
#  id                      :bigint           not null, primary key
#  aasm_state              :string
#  canceled_at             :datetime
#  carrier                 :string
#  dispatched_at           :datetime
#  idempotency_key         :string
#  internal_notes          :text
#  mailed_at               :datetime
#  postage_cost            :decimal(, )
#  recipient_email         :string
#  service                 :string
#  surprise                :boolean
#  tracking_number         :string
#  user_facing_description :string
#  user_facing_title       :string
#  weight                  :decimal(, )
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  address_id              :bigint           not null
#  hc_id                   :string
#  purpose_code_id         :bigint           not null
#  source_tag_id           :bigint           not null
#  user_id                 :bigint           not null
#  zenventory_id           :integer
#
# Indexes
#
#  index_warehouse_orders_on_address_id       (address_id)
#  index_warehouse_orders_on_hc_id            (hc_id)
#  index_warehouse_orders_on_idempotency_key  (idempotency_key) UNIQUE
#  index_warehouse_orders_on_purpose_code_id  (purpose_code_id)
#  index_warehouse_orders_on_source_tag_id    (source_tag_id)
#  index_warehouse_orders_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (purpose_code_id => warehouse_purpose_codes.id)
#  fk_rails_...  (source_tag_id => source_tags.id)
#  fk_rails_...  (user_id => users.id)
#
class Warehouse::Order < ApplicationRecord
  include AASM

  def labor_cost
    # $1.80 base * 20¢/SKU
    1.80 + (0.20 * skus.distinct.count)
  end

  def contents_actual_cost_to_hc
    line_items.joins(:sku).sum("warehouse_skus.actual_cost_to_hc * warehouse_line_items.quantity")
  end

  def contents_declared_unit_cost
    line_items.includes(:sku).sum do |line_item|
      (line_item.sku.declared_unit_cost || 0) * line_item.quantity
    end
  end

  aasm do
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

  belongs_to :purpose_code
  belongs_to :user
  belongs_to :address
  belongs_to :source_tag
  has_many :line_items, dependent: :destroy
  accepts_nested_attributes_for :line_items, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :address

  has_many :skus, through: :line_items
  validates :line_items, presence: true
  validates :recipient_email, presence: true
  validate :can_mail_parcels_to_country

  before_create :set_hc_id

  include HasTableSync
  include HasZenventoryUrl

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

  def cancel!(reason)
    transaction do
      mark_canceled!
      Zenventory.cancel_customer_order(zenventory_id, reason)
    end
  end


  def dispatch!
    ActiveRecord::Base.transaction do
      raise "wrong state" unless may_mark_dispatched?
      order = Zenventory.create_customer_order(
        {
          orderNumber: hc_id,
          customer: {
            name: address.first_name,
            surname: address.last_name || "​",
            email: recipient_email
          }.compact_blank,
          shippingAddress: {
            name: address.name_line,
            line1: address.line_1,
            line2: address.line_2,
            city: address.city,
            state: address.state,
            zip: address.postal_code,
            countryCode: address.country,
            phone: address.phone_number
          }.compact_blank,
          billingAddress: { sameAsShipping: true },
          items: generate_order_items
        }
      )
      mark_dispatched!(order[:id])
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

  def to_param
    hc_id
  end

  private
  def set_hc_id
    ActiveRecord::Base.transaction do
      purpose_code.increment!(:sequence_number)
      self.hc_id = "HC-#{purpose_code.code}-#{purpose_code.sequence_number.to_s.rjust(4, '0')}"
    end
  end

  def can_mail_parcels_to_country
    errors.add(:base, :cant_mail, message: "We can't currently ship to #{ISO3166::Country[address.country]&.common_name || address.country} from the warehouse.") if %i[IR PS CU KP RU].include? address.country&.to_sym
  end
end
