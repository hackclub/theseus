# frozen_string_literal: true

require "rails_helper"

RSpec.describe "letters", type: :request do
  let(:user) { create(:user) }
  let(:letter) { create(:letter, user: user, batch: nil) }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  it "does not wrap the form's cancel link around a submit button" do
    get new_letter_path

    expect(response.body).not_to include(">Cancel</button>")
  end
end
