# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 instant letter queues", type: :request do
  let(:user) { create(:user, can_use_indicia: true) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:api_key) { APIKey.create!(user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_key.token}" } }
  let(:usps_account) { create(:usps_payment_account) }

  let(:queue) do
    Letter::InstantQueue.create!(
      user: user,
      name: "Instant",
      template: "hackatime_template",
      postage_type: "indicia",
      usps_payment_account: usps_account,
      billing_profile: profile,
      letter_height: 4.125,
      letter_width: 9.5,
      letter_weight: 1,
      letter_mailer_id: user.home_mid,
      letter_return_address: user.home_return_address,
      letter_processing_category: 0,
      tags: [ "instant" ],
    )
  end

  let(:params) do
    {
      idempotency_key: "same-key",
      address: { first_name: "Alice", last_name: "Smith", line_1: "123 Main St", city: "Burlington", state: "VT", postal_code: "05401", country: "US" }
    }
  end

  def body = JSON.parse(response.body)

  def submit = post("/api/v1/letter_queues/instant/#{queue.slug}", params: params, headers: headers, as: :json)

  def purchase_raises(&block)
    allow_any_instance_of(USPS::IndiciumPurchase).to receive(:call, &block)
  end

  before do
    fake_hcb!
    allow_any_instance_of(Letter).to receive(:generate_label).and_return(true)
  end

  context "when the charge never went out" do
    it "frees the idempotency key so the same request can be retried" do
      purchase_raises { raise Billing::InFlight, "another transfer is pending" }
      submit
      expect(response).to have_http_status(:payment_required)
      expect(body["error"]).to eq("payment_failed")
      expect(Letter.where(idempotency_key: "same-key")).to be_empty

      allow_any_instance_of(USPS::IndiciumPurchase).to receive(:call).and_return(true)
      submit

      expect(response).to have_http_status(:created), body.to_s
      expect(Letter.find_by!(idempotency_key: "same-key").queue).to eq(queue)
    end
  end

  context "when USPS sold nothing but the charge already round-tripped" do
    it "keeps the money trail, frees the key, and lets the retry through" do
      purchase_raises do |purchase|
        indicium = USPS::Indicium.create!(letter: purchase.letter, payment_account: usps_account, billing_profile: profile, mailing_date: purchase.letter.mailing_date)
        indicium.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: 100)
        raise USPS::IndiciumPurchase::PurchaseFailed.new(StandardError.new("USPS said no"), nil)
      end

      submit
      expect(response).to have_http_status(:bad_gateway)
      expect(body["error"]).to eq("postage_purchase_failed")

      stranded = Letter.order(:id).last
      expect(stranded.usps_indicium).to be_present
      expect(stranded.usps_indicium.ledger_entries.count).to eq(1)
      expect(stranded.idempotency_key).to be_nil

      allow_any_instance_of(USPS::IndiciumPurchase).to receive(:call).and_return(true)
      submit

      expect(response).to have_http_status(:created), body.to_s
      expect(Letter.find_by!(idempotency_key: "same-key")).not_to eq(stranded)
    end
  end

  context "when the outcome is unknown" do
    it "destroys nothing and names the letter in a JSON error" do
      purchase_raises do |purchase|
        indicium = USPS::Indicium.create!(letter: purchase.letter, payment_account: usps_account, billing_profile: profile, mailing_date: purchase.letter.mailing_date)
        raise USPS::IndiciumPurchase::Unrecorded.new(indicium, StandardError.new("could not save"))
      end

      submit

      expect(response).to have_http_status(:conflict)
      expect(response.media_type).to eq("application/json")
      letter = Letter.find_by!(idempotency_key: "same-key")
      expect(body["error"]).to eq("postage_unresolved")
      expect(body["letter_id"]).to eq(letter.public_id)
      expect(letter.usps_indicium).to be_present
    end
  end
end
