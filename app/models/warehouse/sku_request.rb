# frozen_string_literal: true

# == Schema Information
#
# Table name: warehouse_sku_requests
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string           default("draft"), not null
#  assigned_sku_code   :string
#  category            :string
#  country_of_origin   :string
#  customs_description :text
#  description         :text
#  expected_arrival    :date
#  expected_quantity   :integer
#  hs_code             :string
#  name                :string           not null
#  program             :string
#  reviewed_at         :datetime
#  reviewer_notes      :text
#  submitted_at        :datetime
#  suggested_sku_code  :string
#  unit_cost           :decimal(10, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  reviewed_by_id      :bigint
#  user_id             :bigint           not null
#  warehouse_sku_id    :bigint
#
# Indexes
#
#  index_warehouse_sku_requests_on_aasm_state        (aasm_state)
#  index_warehouse_sku_requests_on_reviewed_by_id    (reviewed_by_id)
#  index_warehouse_sku_requests_on_user_id           (user_id)
#  index_warehouse_sku_requests_on_warehouse_sku_id  (warehouse_sku_id)
#
# Foreign Keys
#
#  fk_rails_...  (reviewed_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_sku_id => warehouse_skus.id)
#
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

  CATEGORY_PREFIXES = {
    "sticker" => "Sti", "poster" => "Pri", "card" => "Pri", "flyer" => "Pri",
    "other_printed_material" => "Pri", "hardware" => "Har", "book" => "Boo",
    "swag" => "Swa", "grant" => "Gra", "prize" => "Prz"
  }.freeze

  aasm timestamps: true do
    state :draft, initial: true
    state :submitted
    state :approved
    state :returned
    state :synced

    event :submit do
      transitions from: :draft, to: :submitted
      after { update!(submitted_at: Time.current) }
    end

    event :approve do
      transitions from: :submitted, to: :approved
      after { update!(reviewed_at: Time.current) }
    end

    event :return_for_revision do
      transitions from: :submitted, to: :returned
      after do
        update!(reviewed_at: Time.current)
        return_blocking_pos_to_draft!
      end
    end

    event :revise do
      transitions from: :returned, to: :draft
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

  def suggested_code
    prefix = CATEGORY_PREFIXES[category] || category&.first(3)&.capitalize
    parts = [prefix]
    parts << program&.first(3)&.capitalize if program.present?
    parts << name&.split&.first&.first(3)&.capitalize if name.present?
    parts.compact.join("/")
  end

  def returned?
    aasm_state == "returned"
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

    purchase_order_line_items.where(sku_id: nil).find_each do |li|
      li.update!(sku: sku)
    end

    mark_synced!
  end

  private

  def return_blocking_pos_to_draft!
    purchase_order_line_items.includes(purchase_order: :user).find_each do |li|
      po = li.purchase_order
      next unless po.may_revise?
      po.revise!
      Warehouse::CzarMailer.po_auto_returned(po, self).deliver_later
    end
  end
end
