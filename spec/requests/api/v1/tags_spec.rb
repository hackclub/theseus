# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 tags", type: :request do
  let(:user) { create(:user) }
  let(:api_key) { APIKey.create!(user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }

  before do
    fake_hcb!
  end

  def body = JSON.parse(response.body)

  describe "GET /api/v1/tags" do
    it "returns a list of available tags as JSON" do
      get "/api/v1/tags", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body).to have_key("tags")
      expect(body["tags"]).to be_an(Array)
    end

    it "returns tags from common tags, letters, and warehouse orders" do
      # Create a common tag
      CommonTag.create!(tag: "urgent")
      
      # Create a letter with a tag
      create(:letter, user: user, tags: ["billing"])
      
      get "/api/v1/tags", headers: headers

      expect(response).to have_http_status(:ok)
      tags = body["tags"]
      expect(tags).to include("urgent")
      expect(tags).to include("billing")
    end

    it "requires authentication" do
      get "/api/v1/tags"

      expect(response).not_to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/tags/:id" do
    it "returns tag statistics for a tag with letters" do
      CommonTag.create!(tag: "marketing")
      letter = create(:letter, user: user, tags: ["marketing"], postage: 0.58, aasm_state: "mailed")
      
      get "/api/v1/tags/marketing", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body).to have_key("tag")
      expect(body["tag"]).to eq("marketing")
      expect(body).to have_key("letters")
      expect(body["letters"]).to have_key("count")
      expect(body["letters"]).to have_key("postage_cost")
    end

    it "returns warehouse order statistics along with letters" do
      sku = create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      
      profile = create(:billing_profile, user: user)
      order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test@example.com",
        address: create(:address, country: "US"), billing_profile: profile
      ).tap { |o| o.save!; o.update_columns(tags: ["fulfillment"], aasm_state: "dispatched") }

      get "/api/v1/tags/fulfillment", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body).to have_key("warehouse_orders")
      expect(body["warehouse_orders"]).to have_key("count")
      expect(body["warehouse_orders"]).to have_key("postage_cost")
      expect(body["warehouse_orders"]).to have_key("labor_cost")
      expect(body["warehouse_orders"]).to have_key("contents_cost")
      expect(body["warehouse_orders"]).to have_key("total_cost")
    end

    it "returns 404 when tag has no items" do
      get "/api/v1/tags/nonexistent", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(body["error"]).to eq("no letters or warehouse orders found for tag nonexistent...?")
    end

    it "requires authentication" do
      CommonTag.create!(tag: "test")
      
      get "/api/v1/tags/test"

      expect(response).not_to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/tags/:id/letters" do
    it "only returns the key owner's letters for a tag" do
      other_user = create(:user)
      
      mine = create(:letter, user: user, tags: ["archived"])
      create(:letter, user: other_user, tags: ["archived"])

      get "/api/v1/tags/archived/letters", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body).to have_key("letters")
      expect(body["letters"].map { |l| l["id"] }).to eq([mine.public_id])
    end

    it "returns empty letters for a tag with no items visible to the user" do
      other_user = create(:user)
      create(:letter, user: other_user, tags: ["secret"])

      get "/api/v1/tags/secret/letters", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body["letters"]).to eq([])
    end

    it "requires authentication" do
      get "/api/v1/tags/test/letters"

      expect(response).not_to have_http_status(:ok)
    end
  end
end
