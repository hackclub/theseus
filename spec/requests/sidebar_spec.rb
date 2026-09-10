# frozen_string_literal: true

require "rails_helper"

RSpec.describe "the sidebar", type: :request do
  let(:user) { create(:user) }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  it "renders one mobile toggle, the overlay, and the script that opens them" do
    get root_path

    expect(response.body.scan(/class="sidebar-toggle btn-sm"/).size).to eq(1)
    expect(response.body).to include(%(class="sidebar-overlay"))
    expect(response.body).to include("classList.add('open')")
  end

  it "has scss for the open class the toggle sets" do
    css = Rails.root.join("app/frontend/styles/theseus.scss").read
    mobile = css[/@media \(max-width: 60rem\) \{.*?\n\}/m]

    expect(mobile).to include(".theseus-sidebar")
    expect(mobile).to include(".sidebar-overlay")
    expect(mobile.scan("&.open").size).to eq(2)
  end
end
