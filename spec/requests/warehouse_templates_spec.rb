# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse templates", type: :request do
  let(:user) { create(:user, can_warehouse: true) }
  let(:owner) { create(:user, can_warehouse: true) }
  let(:template) do
    Warehouse::Template.create!(name: "Sticker pack", user: owner, public: true).tap do |t|
      t.line_items.create!(sku: create(:warehouse_sku), quantity: 1)
    end
  end

  before { fake_hcb! }

  it "hides edit and delete on a public template you don't own" do
    sign_in_as(user)
    get warehouse_template_path(template)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(edit_warehouse_template_path(template))
    expect(response.body).not_to include("Delete this template?")
  end

  it "shows them to the owner" do
    sign_in_as(owner)
    get warehouse_template_path(template)

    expect(response.body).to include(edit_warehouse_template_path(template))
    expect(response.body).to include("Delete this template?")
  end

  it "lists templates in index" do
    sign_in_as(user)
    template1 = Warehouse::Template.create!(name: "Template 1", user:, public: false)
    template2 = Warehouse::Template.create!(name: "Template 2", user:, public: true)

    get warehouse_templates_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Template 1")
    expect(response.body).to include("Template 2")
  end

  it "renders create form" do
    sign_in_as(user)
    get new_warehouse_template_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("name")
  end

  it "creates template with line items" do
    sign_in_as(user)
    sku = create(:warehouse_sku)

    post warehouse_templates_path, params: {
      warehouse_template: {
        name: "New template",
        public: true,
        line_items_attributes: [
          { sku_id: sku.id, quantity: 5 }
        ]
      }
    }

    expect(response).to redirect_to(warehouse_template_path(Warehouse::Template.last))
    created = Warehouse::Template.last
    expect(created.name).to eq("New template")
    expect(created.line_items.count).to eq(1)
  end

  it "renders edit form" do
    sign_in_as(owner)
    get edit_warehouse_template_path(template)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(template.name)
  end

  it "updates template name" do
    sign_in_as(owner)

    patch warehouse_template_path(template), params: {
      warehouse_template: {
        name: "Updated pack"
      }
    }

    expect(response).to redirect_to(warehouse_template_path(template))
    expect(template.reload.name).to eq("Updated pack")
  end
end
