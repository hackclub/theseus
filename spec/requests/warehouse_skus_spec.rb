# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse SKUs", type: :request do
  let(:admin) { create_admin }
  let(:sku) { create(:warehouse_sku, enabled: true, ai_enabled: true) }

  before do
    fake_hcb!
    sign_in_as(admin)
  end

  it "indexes SKUs with rendered page" do
    sku1 = create(:warehouse_sku, name: "Widget", enabled: true)
    sku2 = create(:warehouse_sku, name: "Gadget", enabled: true)

    get warehouse_skus_path(include_non_inventory: true)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Widget")
    expect(response.body).to include("Gadget")
  end

  it "filters SKUs by view parameter" do
    create(:warehouse_sku, name: "Sticker", enabled: true)
    get warehouse_skus_path(view: "flat")
    expect(response).to have_http_status(:ok)
  end

  it "shows detail page with stock levels and PO history" do
    sku = create(:warehouse_sku, in_stock: 42, enabled: true)
    po = Warehouse::PurchaseOrder.new(user: admin, supplier_name: "acme").tap do |po|
      po.line_items.build(sku:, quantity: 10, unit_cost: 1.5)
      po.save!
    end

    get warehouse_sku_path(sku)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(sku.name)
    expect(response.body).to include("acme")
  end

  it "can disable a SKU and its AI flag" do
    get edit_warehouse_sku_path(sku)
    expect(response.body).to include('<input type="hidden" name="warehouse_sku[enabled]" value="0">')
    expect(response.body).to include('<input type="hidden" name="warehouse_sku[ai_enabled]" value="0">')

    patch warehouse_sku_path(sku), params: { warehouse_sku: { enabled: "0", ai_enabled: "0" } }
    expect(response).to redirect_to(warehouse_sku_path(sku))
    sku.reload
    expect(sku.enabled).to be(false)
    expect(sku.ai_enabled).to be(false)
  end
end
