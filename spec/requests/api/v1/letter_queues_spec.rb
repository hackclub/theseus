# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 letter queues", type: :request do
  let(:user) { create(:user) }
  let(:api_key) { APIKey.create!(user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }
  let(:owner) { create(:user) }

  let(:params) do
    { address: { first_name: "Alice", last_name: "Smith", line_1: "123 Main St", city: "Burlington", state: "VT", postal_code: "05401", country: "US" } }
  end

  def body = JSON.parse(response.body)

  def build_queue(klass, owner, slug, **extra)
    klass.new({
      user: owner, name: slug, slug: slug,
      letter_height: 4.125, letter_width: 9.5, letter_weight: 1,
      letter_mailer_id: owner.home_mid, letter_return_address: owner.home_return_address,
      letter_processing_category: 0, tags: [ "q" ]
    }.merge(extra)).tap(&:save!)
  end

  before { allow_any_instance_of(Letter).to receive(:generate_label).and_return(true) }

  describe "POST /api/v1/letter_queues/:id (batch queue)" do
    it "accepts letters into the key owner's own queue" do
      queue = build_queue(Letter::Queue, user, "mine")

      post "/api/v1/letter_queues/#{queue.slug}", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created), body.to_s
      expect(queue.letters.count).to eq(1)
    end

    it "will not put letters in somebody else's queue" do
      queue = build_queue(Letter::Queue, owner, "theirs")

      post "/api/v1/letter_queues/#{queue.slug}", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(queue.letters).to be_empty
    end

    it "lets an admin key into anyone's queue" do
      queue = build_queue(Letter::Queue, owner, "theirs")
      admin_key = APIKey.create!(user: create_admin)

      post "/api/v1/letter_queues/#{queue.slug}", params: params, headers: { "Authorization" => "Bearer #{admin_key.token}" }, as: :json

      expect(response).to have_http_status(:created), body.to_s
    end
  end

  describe "POST /api/v1/letter_queues/instant/:id" do
    it "stays open to anyone with a key, by design" do
      queue = build_queue(Letter::InstantQueue, owner, "instant", template: "hackatime_template", postage_type: "stamps")

      post "/api/v1/letter_queues/instant/#{queue.slug}", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created), body.to_s
      expect(queue.letters.count).to eq(1)
    end
  end
end
