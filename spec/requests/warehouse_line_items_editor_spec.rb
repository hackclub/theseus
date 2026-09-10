# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The warehouse line items editor", type: :request do
  let(:admin) { create_admin }
  let!(:sku) { create(:warehouse_sku, in_stock: 5) }
  let!(:sku_request) do
    Warehouse::SKURequest.new(
      user: admin, name: "Pending widget", description: "d", category: Warehouse::SKU.categories.keys.first,
      unit_cost: 1, country_of_origin: "US", expected_arrival: Date.tomorrow, expected_quantity: 1, program: "p",
      aasm_state: "submitted"
    ).tap { |r| r.save!(validate: false) }
  end

  before { sign_in_as(admin) }

  it "offers pending SKU requests on purchase orders, which permit sku_request_id" do
    get new_warehouse_purchase_order_path
    expect(response.body).to include("Pending SKU Requests").and include("Pending widget")
    expect(response.body).to include("line_items_attributes][${idx}][sku_request_id]")
  end

  it "does not offer them on order or template forms, which don't" do
    get new_warehouse_order_path
    expect(response.body).not_to include("Pending SKU Requests")
    expect(response.body).not_to include("sku_request_id]")

    get new_warehouse_template_path
    expect(response.body).not_to include("Pending SKU Requests")
    expect(response.body).not_to include("sku_request_id]")
  end

  it "hides the editor until alpine boots" do
    get new_warehouse_order_path
    expect(response.body).to include("x-cloak")
    expect(File.read(Rails.root.join("app/frontend/styles/components/_migrate_phlex_warehouse.scss"))).to include("[x-cloak] { display: none; }")
  end
end
