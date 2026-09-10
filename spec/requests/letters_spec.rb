# frozen_string_literal: true

require "rails_helper"

RSpec.describe "letters", type: :request do
  let(:user) { create(:user) }
  let(:letter) { create(:letter, user: user, batch: nil) }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  def purchase_indicium!
    letter.update!(postage_type: "indicia")
    USPS::Indicium.create!(
      letter: letter,
      postage: 1,
      fees: 0,
      usps_sku: "DFCM",
      mailing_date: Date.current,
      payment_account: create(:usps_payment_account),
    )
  end

  it "renders a letter whose indicium has been purchased" do
    purchase_indicium!

    get letter_path(letter)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("DFCM")
  end
end
