# frozen_string_literal: true

require "rails_helper"

RSpec.describe "USPS IV-MTR webhook", type: :request do
  let(:headers) do
    password = Rails.application.credentials.dig(:usps, :iv_mtr, :webhook_password)
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("my_best_friend_the_informed_visibility_robot", password)
    }
  end

  def ingest(raw) = post("/webhooks/usps/iv_mtr", params: raw, headers: headers)

  def body = JSON.parse(response.body)

  before { allow(USPS::IVMTR::ImportEventsJob).to receive(:perform_later) }

  it "accepts a real batch" do
    expect {
      ingest({ msgGrpId: "g1", events: [ { "imbMid" => "123456" } ] }.to_json)
    }.to change(USPS::IVMTR::RawJSONBatch, :count).by(1)

    expect(response).to have_http_status(:ok)
    batch = USPS::IVMTR::RawJSONBatch.last
    expect(batch.payload).to eq([ { "imbMid" => "123456" } ])
    expect(USPS::IVMTR::ImportEventsJob).to have_received(:perform_later).with(batch)
  end

  it "400s on something that isn't JSON at all" do
    expect { ingest("not json, sorry") }.not_to change(USPS::IVMTR::RawJSONBatch, :count)

    expect(response).to have_http_status(:bad_request)
    expect(response.media_type).to eq("application/json")
    expect(body["error"]).to be_present
  end

  it "400s on a JSON array" do
    expect { ingest("[]") }.not_to change(USPS::IVMTR::RawJSONBatch, :count)
    expect(response).to have_http_status(:bad_request)
  end

  it "400s when events is missing or isn't an array" do
    expect { ingest("{}") }.not_to change(USPS::IVMTR::RawJSONBatch, :count)
    expect(response).to have_http_status(:bad_request)

    expect { ingest({ events: "nope" }.to_json) }.not_to change(USPS::IVMTR::RawJSONBatch, :count)
    expect(response).to have_http_status(:bad_request)
  end

  it "does not persist a batch with no events" do
    expect { ingest({ events: [] }.to_json) }.not_to change(USPS::IVMTR::RawJSONBatch, :count)
    expect(response).to have_http_status(:ok)
  end

  it "still wants the password" do
    post "/webhooks/usps/iv_mtr", params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end
end
