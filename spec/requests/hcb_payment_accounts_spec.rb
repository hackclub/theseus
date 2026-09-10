# frozen_string_literal: true

require "rails_helper"

RSpec.describe "HCB payment accounts", type: :request do
  let(:user) { create(:user) }
  let(:connection) { create(:hcb_oauth_connection, user: user) }
  let(:profile) { create(:billing_profile, user: user, oauth_connection: connection) }

  before do
    fake_hcb!
    profile
    sign_in_as(user.reload)
  end

  it "does not offer a remove button, because there is no destroy route" do
    get hcb_payment_account_path(profile)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("✕ Remove")
    delete hcb_payment_account_path(profile)
    expect(response).to have_http_status(:not_found)
  end
end
