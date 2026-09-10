# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 warehouse orders", type: :request do
  let(:owner) { create(:user, can_warehouse: true) }
  let(:owner_profile) { create(:billing_profile, user: owner) }
  let(:api_key) { APIKey.create!(user: owner, billing_profile: owner_profile, may_impersonate: true) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }

  let!(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }

  let(:address) do
    { first_name: "Alice", last_name: "Smith", line_1: "123 Main St", city: "Burlington", state: "VT", postal_code: "05401", country: "US" }
  end

  def body = JSON.parse(response.body)

  def payload(idempotency_key: nil, **overrides)
    {
      warehouse_order: { recipient_email: "alice@example.com", user_facing_title: "Stickers", tags: [ "test" ], idempotency_key: idempotency_key }.compact,
      address: address,
      contents: [ { sku: sku.sku, quantity: 1 } ]
    }.merge(overrides)
  end

  before do
    fake_hcb!
    allow(Zenventory).to receive(:create_customer_order).and_return({ id: "zen_1" })
  end

  describe "impersonation and billing profiles" do
    let(:impersonated) { create(:user, can_warehouse: true, slack_id: "U123") }

    it "does not charge the key owner's default profile to the impersonated user" do
      post "/api/v1/warehouse_orders", params: payload.merge(impersonate: impersonated.slack_id), headers: headers, as: :json

      expect(response).to have_http_status(:created), body.to_s
      order = Warehouse::Order.find_by!(hc_id: body.dig("warehouse_order", "id"))
      expect(order.user).to eq(impersonated)
      expect(order.billing_profile).to be_nil
    end

    it "uses a billing profile belonging to the impersonated user when asked" do
      profile = create(:billing_profile, user: impersonated)

      post "/api/v1/warehouse_orders",
        params: payload.merge(impersonate: impersonated.slack_id, billing_profile_id: profile.public_id),
        headers: headers, as: :json

      expect(response).to have_http_status(:created), body.to_s
      expect(Warehouse::Order.find_by!(hc_id: body.dig("warehouse_order", "id")).billing_profile).to eq(profile)
    end

    it "still applies the key's default profile when not impersonating" do
      post "/api/v1/warehouse_orders", params: payload, headers: headers, as: :json

      expect(response).to have_http_status(:created), body.to_s
      expect(Warehouse::Order.find_by!(hc_id: body.dig("warehouse_order", "id")).billing_profile).to eq(owner_profile)
    end
  end

  describe "from_template" do
    it "says the template is missing, not the order" do
      hidden = Warehouse::Template.create!(name: "Secret", user: create(:user), public: false)

      post "/api/v1/warehouse_orders/from_template/#{hidden.public_id}", params: payload, headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(body["error"]).to eq("Template not found")
    end
  end

  describe "a dispatch that fails after the order is saved" do
    before { allow(Zenventory).to receive(:create_customer_order).and_raise(Zenventory::ZenventoryError, "zenventory is asleep") }

    it "returns JSON, not the HTML 500 page" do
      post "/api/v1/warehouse_orders", params: payload(idempotency_key: "abc123"), headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.media_type).to eq("application/json")
      expect(body["error"]).to eq("dispatch_failed")
    end

    it "hands the same draft back to a retry with the same idempotency key" do
      post "/api/v1/warehouse_orders", params: payload(idempotency_key: "abc123"), headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      draft = Warehouse::Order.find_by!(idempotency_key: "abc123")

      post "/api/v1/warehouse_orders", params: payload(idempotency_key: "abc123"), headers: headers, as: :json

      expect(response).to have_http_status(:ok), body.to_s
      expect(body.dig("warehouse_order", "id")).to eq(draft.hc_id)
      expect(Warehouse::Order.where(idempotency_key: "abc123").count).to eq(1)
    end
  end
end
