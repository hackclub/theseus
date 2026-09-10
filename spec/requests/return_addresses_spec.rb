# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Return addresses", type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  before { sign_in_as(user) }

  it "sets an address as default through a real POST form" do
    address = create(:return_address, user: user)
    expect(user.home_return_address).not_to eq(address)

    get return_addresses_path
    expect(response.body).to include(set_as_home_return_address_path(address))
    expect(response.body).not_to include("data-turbo-method")

    post set_as_home_return_address_path(address)
    expect(response).to redirect_to(return_addresses_url)
    expect(user.reload.home_return_address).to eq(address)
  end

  it "does not link a shared address owned by someone else to the edit page" do
    theirs = create(:return_address, user: other, shared: true, name: "Someone Elses Desk")

    get return_addresses_path
    expect(response.body).to include("Someone Elses Desk")
    expect(response.body).not_to include(edit_return_address_path(theirs))
  end

  it "can un-share an address" do
    address = create(:return_address, user: user, shared: true)

    get edit_return_address_path(address)
    expect(response.body).to include('type="hidden" name="return_address[shared]" value="0"')

    patch return_address_path(address), params: { return_address: { shared: "0" } }
    expect(address.reload.shared).to be(false)
  end
end
