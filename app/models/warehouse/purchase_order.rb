# frozen_string_literal: true

# == Schema Information
#
# Table name: warehouse_purchase_orders
#
#  id               :bigint           not null, primary key
#  notes            :text
#  order_number     :string
#  required_by_date :date
#  status           :string           default("draft")
#  supplier_name    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  supplier_id      :integer
#  user_id          :bigint           not null
#  zenventory_id    :integer
#
# Indexes
#
#  index_warehouse_purchase_orders_on_order_number   (order_number)
#  index_warehouse_purchase_orders_on_user_id        (user_id)
#  index_warehouse_purchase_orders_on_zenventory_id  (zenventory_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Warehouse::PurchaseOrder < ApplicationRecord
  has_paper_trail

  include AASM
  include HasZenventoryUrl

  belongs_to :user
  has_many :line_items, class_name: "Warehouse::PurchaseOrderLineItem", foreign_key: :purchase_order_id, dependent: :destroy, inverse_of: :purchase_order

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  validates :supplier_name, presence: true
  validates :line_items, presence: true

  has_zenventory_url "https://app.zenventory.com/printing/printpurchaseorder.php?poid=%s", :zenventory_id

  HUMANIZED_STATES = {
    draft: "Draft",
    open: "Open",
    completed: "Completed",
    deleted: "Deleted"
  }.freeze

  def humanized_state
    HUMANIZED_STATES[status&.to_sym] || status
  end

  aasm column: :status, timestamps: true do
    state :draft, initial: true
    state :open
    state :completed
    state :deleted

    event :mark_open do
      transitions from: :draft, to: :open
    end

    event :mark_completed do
      transitions from: :open, to: :completed
    end

    event :mark_deleted do
      transitions from: %i[draft open], to: :deleted
    end
  end

  def draft?
    status == "draft"
  end

  def open?
    status == "open"
  end

  def completed?
    status == "completed"
  end

  def dispatch!
    ActiveRecord::Base.transaction do
      raise AASM::InvalidTransition, "wrong state" unless may_mark_open?

      po_params = {
        supplier: { id: supplier_id, name: supplier_name }.compact,
        requiredByDate: required_by_date&.iso8601,
        notes: notes,
        items: line_items.map do |li|
          {
            sku: li.sku.sku,
            quantity: li.quantity,
            unitCost: li.unit_cost&.to_f
          }.compact
        end
      }.compact

      response = Zenventory.create_purchase_order(po_params)
      update!(zenventory_id: response[:id], order_number: response[:orderNumber])
      mark_open!
    end
  end

  def sync_from_zenventory!
    return unless zenventory_id.present?

    zenv_po = Zenventory.get_purchase_order(zenventory_id)

    self.supplier_name = zenv_po.dig(:supplier, :name) || supplier_name
    self.supplier_id = zenv_po.dig(:supplier, :id) || supplier_id
    self.order_number = zenv_po[:orderNumber] || order_number
    self.notes = zenv_po[:notes] if zenv_po[:notes].present?
    self.required_by_date = Date.parse(zenv_po[:requiredByDate]) if zenv_po[:requiredByDate].present?

    self.status = if zenv_po[:deleted]
                    "deleted"
                  elsif zenv_po[:completed]
                    "completed"
                  elsif zenv_po[:draft]
                    "draft"
                  else
                    "open"
                  end

    save!
  end

  def total_cost
    line_items.sum { |li| (li.unit_cost || 0) * li.quantity }
  end
end
