# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse SKUs", type: :request do
  let(:admin) { create_admin }
  let(:sku) { create(:warehouse_sku, enabled: true, ai_enabled: true) }

  before { sign_in_as(admin) }

  it "edits without the unit_cost field that has no column behind it" do
    get edit_warehouse_sku_path(sku)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("warehouse_sku[unit_cost]")

    patch warehouse_sku_path(sku), params: { warehouse_sku: { name: "Renamed", unit_cost: "3.50" } }
    expect(response).to redirect_to(warehouse_sku_path(sku))
    expect(sku.reload.name).to eq("Renamed")
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
