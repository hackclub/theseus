# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: warehouse_orders
#
#  id                      :bigint           not null, primary key
#  aasm_state              :string
#  canceled_at             :datetime
#  carrier                 :string
#  contents_cost           :decimal(10, 2)
#  created_via             :integer          default(0), not null
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
#  billing_profile_id      :bigint
#  hc_id                   :string
#  origin_batch_id         :bigint
#  template_id             :bigint
#  user_id                 :bigint           not null
#  zenventory_id           :integer
#
# Indexes
#
#  index_warehouse_orders_on_aasm_state          (aasm_state)
#  index_warehouse_orders_on_address_id          (address_id)
#  index_warehouse_orders_on_batch_id            (batch_id)
#  index_warehouse_orders_on_billing_profile_id  (billing_profile_id)
#  index_warehouse_orders_on_created_via         (created_via)
#  index_warehouse_orders_on_hc_id               (hc_id)
#  index_warehouse_orders_on_idempotency_key     (idempotency_key) UNIQUE
#  index_warehouse_orders_on_origin_batch_id     (origin_batch_id)
#  index_warehouse_orders_on_tags                (tags) USING gin
#  index_warehouse_orders_on_template_id         (template_id)
#  index_warehouse_orders_on_user_id             (user_id)
#  index_warehouse_orders_on_zenventory_id       (zenventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (billing_profile_id => hcb_payment_accounts.id)
#  fk_rails_...  (origin_batch_id => batches.id)
#  fk_rails_...  (template_id => warehouse_templates.id)
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Warehouse::Order do
  let(:user) { create(:user, can_warehouse: true) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }
  let(:template) do
    Warehouse::Template.create!(name: "Sticker pack", user: user, public: true)
                       .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
  end

  def dispatched_order
    order = Warehouse::Order.from_template(
      template,
      user: user,
      recipient_email: "a@b.c",
      address: create(:address, country: "US"),
      billing_profile: profile,
    )
    order.save!
    allow(Zenventory).to receive(:create_customer_order).and_return({ id: 4242 })
    order.dispatch!
    order
  end

  before do
    fake_hcb!
    allow(Zenventory).to receive(:cancel_customer_order).and_return(true)
  end

  describe "canceling" do
    it "voids the pending labor entry nobody has claimed" do
      order = dispatched_order
      entry = order.ledger_entries.labor.sole
      # Nothing charged it yet: a manual order that never made it out the door.
      entry.update!(hcb_transfer: nil, state: :pending, settled_at: nil)

      order.cancel!("customer changed their mind")

      expect(order.reload).to be_canceled
      expect(entry.reload).to be_voided
      expect(entry.metadata["voided_reason"]).to include(order.hc_id)
      expect(entry.metadata).not_to have_key("canceled_after_charge")
    end

    it "leaves a settled labor entry alone and records that it was billed" do
      order = dispatched_order
      entry = order.ledger_entries.labor.sole
      expect(entry).to be_settled

      order.cancel!("too late")

      expect(order.reload).to be_canceled
      expect(entry.reload).to be_settled
      expect(entry.metadata["canceled_after_charge"]).to be(true)
      expect(entry.amount_cents).to eq(200)
    end

    it "leaves an entry claimed by an in-flight transfer alone" do
      order = dispatched_order
      entry = order.ledger_entries.labor.sole
      entry.hcb_transfer.update!(state: :pending)
      entry.update!(state: :pending, settled_at: nil)

      order.cancel!("nope")

      expect(entry.reload).to be_pending
      expect(entry.metadata["canceled_after_charge"]).to be(true)
    end

    it "sweeps labor the same way when the cancellation comes from Zenventory" do
      order = dispatched_order
      entry = order.ledger_entries.labor.sole
      entry.update!(hcb_transfer: nil, state: :pending, settled_at: nil)

      allow(Zenventory).to receive(:get_customer_orders)
        .with(cancelled: true)
        .and_return([ { orderNumber: "hack.club/#{order.hc_id}" } ])

      Warehouse::UpdateCancellationsJob.perform_now

      expect(order.reload).to be_canceled
      expect(entry.reload).to be_voided
    end
  end
end
