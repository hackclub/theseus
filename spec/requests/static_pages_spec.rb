# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Static pages", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create_admin }

  before { fake_hcb! }

  describe "GET /back_office/api-docs" do
    it "renders for an authenticated user" do
      sign_in_as(user)
      get "/back_office/api-docs"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("API")
    end

    it "renders for an unauthenticated user" do
      get "/back_office/api-docs"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("API")
    end
  end

  describe "GET /back_office/problems" do
    it "renders for an admin user" do
      sign_in_as(admin)
      get "/back_office/problems"
      expect(response).to have_http_status(:ok)
    end

    it "redirects for a non-admin user" do
      sign_in_as(user)
      get "/back_office/problems"
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to eq("you can't do that!")
    end
  end
end
