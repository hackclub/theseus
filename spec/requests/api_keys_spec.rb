# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API keys", type: :request do
  let(:user) { create(:user) }
  let(:api_key) { APIKey.create!(user: user, billing_profile: create(:billing_profile, user: user)) }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  it "asks before revoking" do
    get revoke_confirm_api_key_path(api_key)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pull the trigger").and include(revoke_api_key_path(api_key))
  end

  it "revokes" do
    post revoke_api_key_path(api_key)
    expect(response).to redirect_to(api_key_path(api_key))
    expect(api_key.reload).to be_revoked
  end
end
