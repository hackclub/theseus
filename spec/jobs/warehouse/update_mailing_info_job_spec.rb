# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse::UpdateMailingInfoJob do
  let(:user) { create(:user, can_warehouse: true) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }
  let(:template) do
    Warehouse::Template.create!(name: "Sticker pack", user: user, public: true)
                       .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
  end

  def dispatched_order(created_at: nil)
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
    order.update_columns(created_at: created_at) if created_at
    order.reload
  end

  def stub_shipment_report(order)
    allow(Zenventory).to receive(:run_report).and_return([
      {
        order_number: "hack.club/#{order.hc_id}",
        carrier: "USPS",
        service: "Ground Advantage",
        weight: 3,
        tracking_number: "9400100000000000000000",
        shipped_date: "2026-09-09T12:00:00Z",
        shipping_handling: "5.61"
      }
    ])
  end

  before { fake_hcb! }

  it "bills postage for an order created after the billing epoch" do
    order = dispatched_order
    stub_shipment_report(order)

    described_class.perform_now

    expect(order.reload).to be_mailed
    entry = order.ledger_entries.postage.sole
    expect(entry.amount_cents).to eq(561)
  end

  it "does not bill postage for an order that predates the ledger" do
    # The dangerous shape: a legacy order that a backfill just attached a
    # billing profile to. It still ships, it still gets tracking, it just
    # never gets a ledger entry.
    order = dispatched_order(created_at: Warehouse::Order::BILLING_EPOCH - 1.day)
    stub_shipment_report(order)

    described_class.perform_now

    expect(order.reload).to be_mailed
    expect(order.tracking_number).to be_present
    expect(order.ledger_entries.postage).to be_empty
    expect(HCB::Transfer.where(hq_organization_id: ENV.fetch("HCB_WAREHOUSE_ORG_ID")).count).to eq(1) # labor only
  end
end
