# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Return addresses", type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  before do
    fake_hcb!
    sign_in_as(user)
  end

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

  it "shows index with both shared and owned addresses" do
    # Create owned address
    owned = create(:return_address, user: user, name: "My Office")
    # Create shared address from another user
    shared = create(:return_address, user: other, shared: true, name: "Shared Desk")
    # Create another address owned by other but NOT shared
    other_private = create(:return_address, user: other, shared: false, name: "Private Desk")

    get return_addresses_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("My Office")
    expect(response.body).to include("Shared Desk")
    expect(response.body).not_to include("Private Desk")
  end

  it "shows new form" do
    get new_return_address_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("form")
  end

  it "creates a return address with valid params" do
    post return_addresses_path, params: {
      return_address: {
        name: "My Headquarters",
        line_1: "456 Oak Ave",
        line_2: "Suite 100",
        city: "Boston",
        state: "MA",
        postal_code: "02101",
        country: "US"
      }
    }

    expect(response).to redirect_to(return_addresses_url)
    address = ReturnAddress.last
    expect(address.name).to eq("My Headquarters")
    expect(address.line_1).to eq("456 Oak Ave")
    expect(address.city).to eq("Boston")
    expect(address.user).to eq(user)
  end

  it "creates a return address from letter form and redirects" do
    post return_addresses_path, params: {
      from_letter: "true",
      return_address: {
        name: "Letter Office",
        line_1: "789 Pine St",
        city: "Denver",
        state: "CO",
        postal_code: "80202",
        country: "US"
      }
    }

    expect(response).to redirect_to(new_letter_path)
    address = ReturnAddress.last
    expect(address.name).to eq("Letter Office")
    expect(address.user).to eq(user)
  end

  it "shows edit form for owned address" do
    address = create(:return_address, user: user, name: "Editable Address")

    get edit_return_address_path(address)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Editable Address")
  end

  it "updates a return address with valid params" do
    address = create(:return_address, user: user, name: "Old Name", city: "Boston")

    patch return_address_path(address), params: {
      return_address: {
        name: "New Name",
        city: "Portland"
      }
    }

    expect(response).to redirect_to(return_addresses_url)
    expect(address.reload.name).to eq("New Name")
    expect(address.reload.city).to eq("Portland")
  end

  it "updates a return address from letter form and redirects" do
    address = create(:return_address, user: user, name: "Letter Address", city: "Seattle")

    patch return_address_path(address), params: {
      from_letter: "true",
      return_address: {
        name: "Updated Letter Address",
        city: "Portland"
      }
    }

    expect(response).to redirect_to(new_letter_path)
    expect(address.reload.name).to eq("Updated Letter Address")
    expect(address.reload.city).to eq("Portland")
  end
end
