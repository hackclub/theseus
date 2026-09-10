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
end
