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
end
