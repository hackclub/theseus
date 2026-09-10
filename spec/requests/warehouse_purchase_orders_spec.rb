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

  before { sign_in_as(user) }

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
end
