# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:admin) { create_admin }
  let(:other) { create(:user) }

  before do
    # The impersonate route sits behind a routing constraint that reads the real
    # session, which request specs can't set.
    allow(AdminConstraint).to receive(:matches?).and_return(true)
    sign_in_as(admin)
  end

  it "keeps you logged in when you stop impersonating twice" do
    post impersonate_user_path(other)
    expect(session[:user_id]).to eq(other.id)
    expect(session[:impersonator_user_id]).to eq(admin.id)

    delete stop_impersonating_path
    expect(session[:user_id]).to eq(admin.id)

    delete stop_impersonating_path
    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to eq(admin.id)
  end
end
