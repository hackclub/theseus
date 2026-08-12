# frozen_string_literal: true

class Warehouse::SKURequest < ApplicationRecord
  has_paper_trail
  include AASM

  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :warehouse_sku, class_name: "Warehouse::SKU", optional: true

  has_many :purchase_order_line_items, class_name: "Warehouse::PurchaseOrderLineItem",
           foreign_key: :sku_request_id, dependent: :nullify

  has_one_attached :image

  validates :name, presence: true
  validates :unit_cost, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true, inclusion: { in: Warehouse::SKU.categories.keys }
  validates :expected_quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :assigned_sku_code, presence: true, if: -> { approved? || synced? }

  aasm timestamps: true do
    state :draft, initial: true
    state :submitted
    state :approved
    state :rejected
    state :synced

    event :submit do
      transitions from: :draft, to: :submitted
      after { update!(submitted_at: Time.current) }
    end

    event :approve do
      transitions from: :submitted, to: :approved
      after { update!(reviewed_at: Time.current) }
    end

    event :reject do
      transitions from: :submitted, to: :rejected
      after { update!(reviewed_at: Time.current) }
    end

    event :mark_synced do
      transitions from: :approved, to: :synced
    end
  end

  def blocking_purchase_orders
    purchase_order_line_items
      .includes(purchase_order: :user)
      .map(&:purchase_order)
      .uniq
  end

  def display_name
    name
  end

  # Call AFTER approve! — separated so zenventory failure doesn't
  # roll back the state transition. Idempotent: checks warehouse_sku.
  def create_sku_in_zenventory!
    return if warehouse_sku.present?

    params = {
      sku: assigned_sku_code,
      description: name,
      category: category&.humanize,
      unitCost: unit_cost&.to_f,
      userField1: country_of_origin,
      userField2: hs_code
    }.compact

    response = Zenventory.create_item(params)
    zen_id = response[:id].to_s

    sku = Warehouse::SKU.create!(
      sku: assigned_sku_code,
      name: name,
      description: description,
      category: category,
      country_of_origin: country_of_origin,
      hs_code: hs_code,
      customs_description: customs_description,
      average_po_cost: unit_cost,
      zenventory_id: zen_id,
      enabled: true
    )

    update!(warehouse_sku: sku)

    # Resolve any PO line items waiting on this request
    purchase_order_line_items.where(sku_id: nil).find_each do |li|
      li.update!(sku: sku)
    end

    mark_synced!
  end
end
