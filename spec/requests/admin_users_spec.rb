# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin users", type: :request do
  let(:admin) { create_admin }
  let(:other) { create(:user, username: "someone-else") }

  before { sign_in_as(admin) }

  it "renders another user's page with a feature flag present" do
    Flipper.add(:require_billing_profile_2026_09_08)
    get admin_user_path(other)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("require_billing_profile_2026_09_08")
    expect(response.body).to include(CGI.escape_html(flip_admin_user_path(other, flag: "require_billing_profile_2026_09_08", state: true)))
  end

  it "counts warehouse orders in the orders column" do
    template = Warehouse::Template.create!(name: "Sticker pack", user: other)
    template.line_items.create!(sku: create(:warehouse_sku), quantity: 1)
    Warehouse::Order.from_template(template, user: other, recipient_email: "a@b.c", address: create(:address, country: "US")).save!

    get admin_users_path
    expect(response).to have_http_status(:ok)
    orders_cells = response.body.scan(%r{<td class="text-muted">(\d+)</td>})
    expect(orders_cells).to include([ "1" ])
  end

  it "does not blow up when flip is called without a flag" do
    post flip_admin_user_path(other)
    expect(response).to redirect_to(admin_user_path(other))
    expect(flash[:alert]).to be_present
  end

  it "renders admin users index" do
    create(:user, username: "alice")
    create(:user, username: "bob")

    get admin_users_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("alice")
    expect(response.body).to include("bob")
  end

  it "renders a specific admin user's show page" do
    get admin_user_path(other)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(other.username)
    expect(response.body).to include(other.email)
  end

  it "renders edit form for a user" do
    get edit_admin_user_path(other)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(other.username)
  end

  it "updates user permissions via edit form" do
    expect(other.is_warehouse_czar?).to be false

    patch admin_user_path(other), params: {
      user: {
        is_warehouse_czar: "1",
        can_use_indicia: "1"
      }
    }

    expect(response).to redirect_to(admin_user_path(other))
    other.reload
    expect(other.is_warehouse_czar?).to be true
    expect(other.can_use_indicia?).to be true
  end

  it "flips a feature flag for a specific user" do
    post flip_admin_user_path(other), params: { flag: "test_feature", state: "true" }

    expect(response).to redirect_to(admin_user_path(other))
    expect(flash[:notice]).to include("test_feature")
    expect(flash[:notice]).to include("enabled")
  end
end
