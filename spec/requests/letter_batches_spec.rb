# frozen_string_literal: true

require "rails_helper"

RSpec.describe "letter batches", type: :request do
  let(:user) { create(:user) }
  let(:batch) { create(:letter_batch, user: user) }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  it "lets a user without warehouse access open their own batch" do
    get letter_batch_path(batch)
    expect(response).to have_http_status(:ok)
  end

  it "re-renders the edit form when the update fails validation" do
    patch letter_batch_path(batch), params: { letter_batch: { letter_height: -1 } }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Letter height must be greater than 0")
  end

  it "flags rows going where USPS doesn't deliver on the validate page" do
    batch.csv.attach(
      io: StringIO.new("first_name,last_name,address,city,state,zip,country\nEve,Kim,1 Street,Pyongyang,Pyongyang,00000,North Korea\n"),
      filename: "test.csv", content_type: "text/csv"
    )
    mapping = { "first_name" => "first_name", "last_name" => "last_name", "address" => "line_1", "city" => "city", "state" => "state", "zip" => "postal_code", "country" => "country" }

    post set_mapping_letter_batch_path(batch), params: { field_mapping: mapping }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("USPS doesn&#39;t deliver to North Korea")
  end
end
