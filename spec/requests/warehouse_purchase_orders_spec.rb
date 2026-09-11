# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse purchase orders", type: :request do
  let(:user) { create(:user, can_warehouse: true) }
  let(:purchase_order) do
    Warehouse::PurchaseOrder.new(user: user, supplier_name: "acme").tap do |po|
      po.line_items.build(sku: create(:warehouse_sku), quantity: 1, unit_cost: 1)
      po.save!
    end
  end

  before do
    fake_hcb!
    sign_in_as(user)
  end

  it "walks a returned purchase order back to submitted" do
    purchase_order.update!(status: "returned")

    get warehouse_purchase_order_path(purchase_order)
    expect(response.body).to include(revise_warehouse_purchase_order_path(purchase_order))
    expect(response.body).not_to include(submit_for_approval_warehouse_purchase_order_path(purchase_order))

    post revise_warehouse_purchase_order_path(purchase_order)
    expect(response).to redirect_to(edit_warehouse_purchase_order_path(purchase_order))
    expect(purchase_order.reload).to be_draft

    get warehouse_purchase_order_path(purchase_order)
    expect(response.body).to include(submit_for_approval_warehouse_purchase_order_path(purchase_order))

    post submit_for_approval_warehouse_purchase_order_path(purchase_order)
    expect(response).to redirect_to(warehouse_purchase_order_path(purchase_order))
    expect(purchase_order.reload).to be_submitted
  end

  it "creates purchase order with line items" do
    sku = create(:warehouse_sku, name: "Widget", declared_unit_cost_override: 2.0)

    post warehouse_purchase_orders_path, params: {
      warehouse_purchase_order: {
        supplier_name: "ACME Corp",
        line_items_attributes: [
          { sku_id: sku.id, quantity: 5, unit_cost: 1.50 }
        ]
      }
    }

    expect(response).to redirect_to(warehouse_purchase_order_path(Warehouse::PurchaseOrder.last))
    po = Warehouse::PurchaseOrder.last
    expect(po.supplier_name).to eq("ACME Corp")
    expect(po.line_items.count).to eq(1)
    expect(po.line_items.first.sku_id).to eq(sku.id)
  end

  it "shows purchase order with status badge" do
    po = Warehouse::PurchaseOrder.new(user: user, supplier_name: "Supplier").tap do |o|
      o.line_items.build(sku: create(:warehouse_sku), quantity: 2, unit_cost: 3.0)
      o.save!
      o.submit_for_approval!
    end

    get warehouse_purchase_order_path(po)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Supplier")
    expect(response.body).to include("Submitted")
  end

  it "submits purchase order for approval" do
    po = purchase_order
    expect(po).to be_draft

    post submit_for_approval_warehouse_purchase_order_path(po)
    expect(response).to redirect_to(warehouse_purchase_order_path(po))
    expect(po.reload).to be_submitted
  end
end
