require "rails_helper"

RSpec.describe API::V1::Warehouse::SKUsController, type: :request do
  let!(:home_mid) { USPS::MailerId.create!(name: "Test MID", crid: "123456", mid: "987654") }
  let!(:home_return_address) { ReturnAddress.create! }
  let!(:sku) { create(:warehouse_sku, name: "Warehouse Sticker", in_stock: 42, inbound: 9) }

  let(:user) do
    User.create!(
      username: "Warehouse User",
      email: "warehouse-user@example.com",
      can_warehouse:,
      home_mid: home_mid,
      home_return_address: home_return_address,
    )
  end
  before do
    allow_any_instance_of(API::V1::ApplicationController).to receive(:authenticate!) do |controller|
      controller.instance_variable_set(:@current_user, user)
    end
  end

  describe "GET /api/v1/warehouse/skus/:id" do
    context "when user can use warehouse" do
      let(:can_warehouse) { true }

      it "returns SKU name and inventory levels" do
        get "/api/v1/warehouse/skus/#{sku.id}"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(
          "sku" => {
            "name" => "Warehouse Sticker",
            "in_stock" => 42,
            "inbound" => 9
          }
        )
      end
    end

    context "when user cannot use warehouse" do
      let(:can_warehouse) { false }

      it "does not expose SKU records" do
        get "/api/v1/warehouse/skus/#{sku.id}"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include("error" => "resource_not_found")
      end
    end
  end
end
