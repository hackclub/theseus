# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 letters", type: :request do
  let(:user) { create(:user) }
  let(:api_key) { APIKey.create!(user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }

  let(:stranger) { create(:user) }

  def body = JSON.parse(response.body)

  describe "GET /api/v1/letters/:id" do
    it "shows the key owner's own letter" do
      letter = create(:letter, user: user)

      get "/api/v1/letters/#{letter.public_id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body.dig("letter", "id")).to eq(letter.public_id)
    end

    it "refuses somebody else's letter" do
      letter = create(:letter, user: stranger)

      get "/api/v1/letters/#{letter.public_id}", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(body["error"]).to eq("not_authorized")
    end

    it "lets an admin key see anything" do
      letter = create(:letter, user: stranger)
      admin_key = APIKey.create!(user: create_admin)

      get "/api/v1/letters/#{letter.public_id}", headers: { "Authorization" => "Bearer #{admin_key.token}" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/tags/:id/letters" do
    it "only returns the key owner's letters" do
      mine = create(:letter, user: user, tags: [ "shared" ])
      create(:letter, user: stranger, tags: [ "shared" ])

      get "/api/v1/tags/shared/letters", headers: headers

      expect(response).to have_http_status(:ok)
      expect(body["letters"].map { |l| l["id"] }).to eq([ mine.public_id ])
    end
  end

  describe "the back office letter page" do
    let(:letter) { create(:letter, user: stranger) }

    it "still opens for the owner" do
      sign_in_as(letter.user)
      get letter_path(letter)
      expect(response).to have_http_status(:ok)
    end

    it "still opens for an admin" do
      sign_in_as(create_admin)
      get letter_path(letter)
      expect(response).to have_http_status(:ok)
    end

    it "still opens for the owner of the batch the letter came in on" do
      sign_in_as(letter.batch.user)
      get letter_path(letter)
      expect(response).to have_http_status(:ok)
    end

    it "still opens for the owner of the queue the letter was submitted to" do
      queue = Letter::Queue.new(
        user: user, name: "Queue", letter_height: 1, letter_width: 1, letter_weight: 1,
        letter_mailer_id: user.home_mid, letter_return_address: user.home_return_address,
        letter_processing_category: 0, tags: [ "q" ],
      ).tap(&:save!)
      letter.update!(queue: queue)

      sign_in_as(user)
      get letter_path(letter)
      expect(response).to have_http_status(:ok)
    end

    it "is closed to an unrelated user" do
      sign_in_as(create(:user))
      get letter_path(letter)
      expect(response).not_to have_http_status(:ok)
    end
  end
end
