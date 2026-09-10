# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API error rendering", type: :request do
  let(:user) { create(:user) }
  let(:api_key) { APIKey.create!(user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }

  def body = JSON.parse(response.body)

  it "turns an invalid state transition into a 422 instead of a 500" do
    letter = create(:letter, user: user, aasm_state: "mailed")

    post "/api/v1/letters/#{letter.public_id}/mark_mailed", headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.media_type).to eq("application/json")
    expect(body["error"]).to eq("invalid_transition")
  end

  it "renders JSON, not the HTML 500 page, for anything unhandled" do
    letter = create(:letter, user: user)
    allow_any_instance_of(Letter).to receive(:mark_printed!).and_raise(Redis::BaseError, "boom")

    post "/api/v1/letters/#{letter.public_id}/mark_printed", headers: headers

    expect(response).to have_http_status(:internal_server_error)
    expect(response.media_type).to eq("application/json")
    expect(body).to eq({ "error" => "internal_error" })
  end

  it "does the same on the public api" do
    public_user = Public::User.create!(email: "someone@example.com", hca_id: "hca_err")
    key = Public::APIKey.create!(public_user: public_user)
    allow(Letter).to receive(:where).and_raise(Redis::BaseError, "boom")

    get "/api/public/v1/letters", headers: { "Authorization" => "Bearer #{key.token}" }

    expect(response).to have_http_status(:internal_server_error)
    expect(response.media_type).to eq("application/json")
    expect(body).to eq({ "error" => "internal_error" })
  end
end
