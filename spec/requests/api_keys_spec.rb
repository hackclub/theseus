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

  it "offers the qz_only checkbox to admins and permits it" do
    admin = create_admin
    sign_in_as(admin)

    get new_api_key_path
    expect(response.body).to include(%(name="api_key[qz_only]"))

    post api_keys_path, params: { api_key: { name: "printer", qz_only: "1" } }
    expect(APIKey.order(:id).last).to be_qz_only
  end

  it "hides the qz_only checkbox from non-admins" do
    get new_api_key_path

    expect(response.body).not_to include(%(name="api_key[qz_only]"))
  end

  it "shows the abbreviated token, with the full one only in the copy attribute" do
    get api_key_path(api_key)

    expect(response.body).to include(api_key.abbreviated)
    expect(response.body).to include(%(data-copy-to-clipboard="#{api_key.token}"))
    expect(response.body).not_to match(/>\s*#{Regexp.escape(api_key.token)}\s*</)
  end
end
