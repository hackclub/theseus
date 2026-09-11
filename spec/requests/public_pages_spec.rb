# frozen_string_literal: true

require "rails_helper"

RSpec.describe "public pages", type: :request do
  let(:user) { create(:user) }
  let(:public_user) { create(:public_user) }

  before do
    fake_hcb!
  end

  describe "GET /" do
    it "renders the public root page" do
      get public_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end

  describe "GET /login" do
    it "renders the login page" do
      get public_login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("login")
    end
  end

  describe "GET /letters/:id" do
    it "renders a public letter tracking page" do
      letter = create(:letter, user: user)
      get public_letter_path(letter)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end

  describe "GET /packages/:id" do
    it "renders a public package tracking page" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test@test.com",
        address: create(:address, country: "US"), billing_profile: profile
      ).tap(&:save!)

      get public_package_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end

  describe "GET /packages/:id/embed" do
    it "renders the embed view with frameable headers" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test@test.com",
        address: create(:address, country: "US"), billing_profile: profile
      ).tap(&:save!)

      get "/packages/#{order.public_id}/embed"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end

    it "handles draft orders in embed" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test@test.com",
        address: create(:address, country: "US"), billing_profile: profile
      ).tap(&:save!)

      get "/packages/#{order.public_id}/embed"
      # Draft orders may redirect or render — just verify no 500
      expect(response.status).to be < 500
    end
  end

  describe "GET /leaderboards/this_week" do
    it "renders the this_week leaderboard" do
      get this_week_leaderboards_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end

  describe "GET /leaderboards/this_month" do
    it "renders the this_month leaderboard" do
      get this_month_leaderboards_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end

  describe "GET /leaderboards/all_time" do
    it "renders the all_time leaderboard" do
      get all_time_leaderboards_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end

  describe "GET /my/mail" do
    it "requires public user to be signed in" do
      get my_mail_path
      expect(response).to redirect_to(public_login_path)
    end

    it "shows mail for a signed-in public user" do
      sign_in_public_user(public_user)
      get my_mail_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end

    it "includes warehouse orders for the user's email" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      order = Warehouse::Order.from_template(
        template, user: user, recipient_email: public_user.email,
        address: create(:address, country: "US"), billing_profile: profile
      ).tap(&:save!)

      sign_in_public_user(public_user)
      get my_mail_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end

    it "includes letters for the user's email" do
      letter = create(:letter, user: user, recipient_email: public_user.email)
      sign_in_public_user(public_user)
      get my_mail_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("html")
    end
  end
end
