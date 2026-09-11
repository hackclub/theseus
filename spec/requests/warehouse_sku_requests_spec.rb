# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse SKU requests", type: :request do
  let(:user) { create(:user, can_warehouse: true) }

  let(:attributes) do
    {
      name: "Sticker",
      description: "a sticker",
      category: Warehouse::SKU.categories.keys.first,
      unit_cost: 1,
      country_of_origin: "US",
      program: "Athena",
      expected_arrival: Date.tomorrow.to_s,
      expected_quantity: 10
    }
  end

  def image = fixture_file_upload("item.png", "image/png")

  before do
    fake_hcb!
    sign_in_as(user)
  end

  it "renders the new form as multipart" do
    get new_warehouse_sku_request_path
    expect(response.body).to include('enctype="multipart/form-data"')
  end

  it "creates with an uploaded image" do
    post warehouse_sku_requests_path, params: { warehouse_sku_request: attributes.merge(image: image) }
    sku_request = Warehouse::SKURequest.last
    expect(response).to redirect_to(warehouse_sku_request_path(sku_request))
    expect(sku_request.image).to be_attached
  end

  it "keeps the image when editing without picking a new file" do
    sku_request = Warehouse::SKURequest.new(attributes.merge(user: user))
    sku_request.image.attach(image)
    sku_request.save!

    patch warehouse_sku_request_path(sku_request), params: { warehouse_sku_request: { name: "Sticker II", image: "" } }

    expect(response).to redirect_to(warehouse_sku_request_path(sku_request))
    expect(sku_request.reload.name).to eq("Sticker II")
    expect(sku_request.image).to be_attached
  end

  it "shows SKU request page" do
    sku_request = Warehouse::SKURequest.new(attributes.merge(user:))
    sku_request.image.attach(image)
    sku_request.save!

    get warehouse_sku_request_path(sku_request)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(sku_request.name)
    expect(response.body).to include(sku_request.description)
  end
end
