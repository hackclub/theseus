# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 warehouse SKUs", type: :request do
  let(:user) { create(:user, can_warehouse: true) }
  let(:api_key) { APIKey.create!(user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }

  def body = JSON.parse(response.body)

  before { fake_hcb! }

  describe "GET /api/v1/warehouse/skus" do
    it "returns enabled in-inventory SKUs" do
      visible = create(:warehouse_sku, name: "Visible", enabled: true, in_stock: 10, inbound: 5)
      create(:warehouse_sku, name: "Disabled", enabled: false, in_stock: 10, inbound: 5)
      create(:warehouse_sku, name: "No Inventory", enabled: true, in_stock: nil, inbound: nil)

      get "/api/v1/warehouse/skus", headers: headers

      expect(response).to have_http_status(:ok)
      skus = body["skus"]
      expect(skus.length).to eq(1)
      expect(skus.first["sku"]).to eq(visible.sku)
      expect(skus.first["name"]).to eq("Visible")
      expect(skus.first["in_stock"]).to eq(10)
      expect(skus.first["inbound"]).to eq(5)
    end

    it "includes cost and customs fields" do
      create(:warehouse_sku, enabled: true, in_stock: 100, inbound: 0,
        declared_unit_cost_override: 1.50, average_po_cost: 1.25, actual_cost_to_hc: 1.10,
        country_of_origin: "CN", customs_description: "Vinyl sticker", hs_code: "4911.91")

      get "/api/v1/warehouse/skus", headers: headers

      sku = body["skus"].first
      expect(sku["unit_cost"]).to eq("1.5")
      expect(sku["average_po_cost"]).to eq("1.25")
      expect(sku["actual_cost_to_hc"]).to eq("1.1")
      expect(sku["country_of_origin"]).to eq("CN")
      expect(sku["customs_description"]).to eq("Vinyl sticker")
      expect(sku["hs_code"]).to eq("4911.91")
    end

    it "returns all SKUs with ?all=true" do
      create(:warehouse_sku, name: "Active", enabled: true, in_stock: 10, inbound: 5)
      create(:warehouse_sku, name: "Disabled", enabled: false, in_stock: 10, inbound: 5)
      create(:warehouse_sku, name: "No Inventory", enabled: true, in_stock: nil, inbound: nil)

      get "/api/v1/warehouse/skus?all=true", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body["skus"].length).to eq(3)
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/warehouse/skus"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/warehouse/skus/:sku_code" do
    it "returns a single SKU by its code (including slashes)" do
      sku = create(:warehouse_sku, sku: "Sti/Test/1st", in_stock: 42, inbound: 10, declared_unit_cost_override: 2.0)

      get "/api/v1/warehouse/skus/#{sku.sku}", headers: headers

      expect(response).to have_http_status(:ok)
      data = body["sku"]
      expect(data["sku"]).to eq(sku.sku)
      expect(data["in_stock"]).to eq(42)
      expect(data["unit_cost"]).to eq("2.0")
    end

    it "returns 404 for unknown SKU" do
      get "/api/v1/warehouse/skus/Fake/Sku/999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
