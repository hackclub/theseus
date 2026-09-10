# frozen_string_literal: true

require "rails_helper"

RSpec.describe "public id lookup", type: :request do
  let(:admin) { create_admin }

  before do
    fake_hcb!
    sign_in_as(admin)
  end

  def lookup(id) = post(lookup_public_ids_path, params: { id: id })

  it "sends letters and orders to their pages" do
    letter = create(:letter, user: admin)
    lookup letter.public_id
    expect(response).to redirect_to(letter_path(letter))
  end

  it "sends a user to the admin user page" do
    lookup admin.public_id
    expect(response).to redirect_to(admin_user_path(admin))
  end

  it "sends a billing profile to its payment account page" do
    profile = create(:billing_profile, user: admin)
    lookup profile.public_id
    expect(response).to redirect_to(hcb_payment_account_path(profile))
  end

  it "sends a letter batch to its batch page" do
    batch = create(:letter_batch, user: admin)
    lookup batch.public_id
    expect(response).to redirect_to(letter_batch_path(batch))
  end

  it "sends an indicium to the inspector for admins" do
    letter = create(:letter, user: admin)
    indicium = USPS::Indicium.create!(letter: letter, payment_account: create(:usps_payment_account), mailing_date: letter.mailing_date)
    lookup indicium.public_id
    expect(response).to redirect_to(inspect_indicium_path(indicium))
  end

  it "says so instead of blowing up when a record has no page" do
    public_user = Public::User.create!(email: "someone@example.com", hca_id: "hca_1")

    lookup public_user.public_id

    expect(response).to redirect_to(public_ids_path)
    expect(flash[:alert]).to include("no page for it")
  end
end
