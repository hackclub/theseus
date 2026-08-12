# frozen_string_literal: true

# == Schema Information
#
# Table name: warehouse_purchase_orders
#
#  id               :bigint           not null, primary key
#  notes            :text
#  order_number     :string
#  rejection_reason :text
#  required_by_date :date
#  reviewed_at      :datetime
#  status           :string           default("draft")
#  submitted_at     :datetime
#  supplier_name    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  reviewed_by_id   :bigint
#  supplier_id      :integer
#  user_id          :bigint           not null
#  zenventory_id    :integer
#
# Indexes
#
#  index_warehouse_purchase_orders_on_order_number    (order_number)
#  index_warehouse_purchase_orders_on_reviewed_by_id  (reviewed_by_id)
#  index_warehouse_purchase_orders_on_user_id         (user_id)
#  index_warehouse_purchase_orders_on_zenventory_id   (zenventory_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (reviewed_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class Warehouse::PurchaseOrder < ApplicationRecord
  has_paper_trail

  include AASM
  include HasZenventoryUrl

  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :line_items, class_name: "Warehouse::PurchaseOrderLineItem", foreign_key: :purchase_order_id, dependent: :destroy, inverse_of: :purchase_order

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  validates :supplier_name, presence: true
  validates :line_items, presence: true

  has_zenventory_url "https://app.zenventory.com/printing/printpurchaseorder.php?poid=%s", :zenventory_id

  HUMANIZED_STATES = {
    draft: "Draft",
    submitted: "Submitted",
    approved: "Approved",
    rejected: "Rejected",
    open: "Sent to Zenventory",
    completed: "Completed",
    deleted: "Deleted"
  }.freeze

  def humanized_state
    HUMANIZED_STATES[status&.to_sym] || status
  end

  aasm column: :status, timestamps: true do
    state :draft, initial: true
    state :submitted
    state :approved
    state :rejected
    state :open
    state :completed
    state :deleted

    event :submit_for_approval do
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

    event :revise do
      transitions from: :rejected, to: :draft
    end

    event :mark_open do
      transitions from: :approved, to: :open, guard: :all_skus_resolved?
    end

    event :mark_completed do
      transitions from: :open, to: :completed
    end

    event :mark_deleted do
      transitions from: %i[draft submitted approved rejected open], to: :deleted
    end
  end

  def draft?
    status == "draft"
  end

  def submitted?
    status == "submitted"
  end

  def approved?
    status == "approved"
  end

  def open?
    status == "open"
  end

  def completed?
    status == "completed"
  end

  def all_skus_resolved?
    line_items.all? { |li| li.sku_id.present? }
  end

  def unresolved_sku_requests
    line_items.includes(:sku_request).where(sku_id: nil).filter_map(&:sku_request)
  end

  def blocked_on_skus?
    approved? && !all_skus_resolved?
  end

  def dispatch!
    ActiveRecord::Base.transaction do
      raise "Not all SKUs resolved" unless all_skus_resolved?
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
