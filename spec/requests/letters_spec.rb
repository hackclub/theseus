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

  it "does not wrap the form's cancel link around a submit button" do
    get new_letter_path

    expect(response.body).not_to include(">Cancel</button>")
  end

  describe "updating a batch letter" do
    let(:batch_letter) { create(:letter, user: user, postage_type: "stamps") }

    it "accepts an edit that resends the current postage type" do
      patch letter_path(batch_letter), params: { letter: { user_facing_title: "renamed", postage_type: "stamps" } }

      expect(response).to redirect_to(letter_path(batch_letter))
      expect(batch_letter.reload.user_facing_title).to eq("renamed")
    end

    it "still refuses to change the postage type" do
      patch letter_path(batch_letter), params: { letter: { user_facing_title: "renamed", postage_type: "indicia" } }

      expect(flash[:alert]).to include("Cannot change postage type")
      expect(batch_letter.reload.user_facing_title).to be_nil
    end
  end

  describe "the show page" do
    it "names the template select so generate_label can read it, and offers the qr checkbox" do
      get letter_path(letter)

      expect(response.body).to include('name="template"')
      expect(response.body).not_to include('name="[template]"')
      expect(response.body).to include('name="qr"')
    end

    it "generates a label with the picked template" do
      template = SnailMail::Components::Registry.available_single_templates.last.to_s

      post generate_label_letter_path(letter), params: { template: template, qr: "1" }

      expect(letter.reload.label).to be_attached
    end

    it "offers to switch a loose stamps letter to indicia" do
      get letter_path(letter)

      expect(response.body).to include("Switch to Indicia")
    end

    it "offers mark printed for a batch letter that has no label of its own" do
      batch_letter = create(:letter, user: user)

      get letter_path(batch_letter)

      expect(response.body).to include(mark_printed_letter_path(batch_letter))
    end

    # preview_template is only routed in development, so linking to it outside
    # development raises on the path helper before it can leak.
    it "hides delete and the dev-only template preview from a non-admin owner" do
      letter.label.attach(io: StringIO.new("%PDF-1.4"), filename: "label.pdf", content_type: "application/pdf")

      get letter_path(letter)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Delete this letter?")
      expect(response.body).not_to include("Preview template")
    end

    it "shows delete to an admin" do
      sign_in_as(create_admin)

      get letter_path(letter)

      expect(response.body).to include("Delete this letter?")
    end

    it "shows clear orphaned indicium to admins only" do
      purchase_indicium!

      get letter_path(letter)
      expect(response.body).not_to include("Clear orphaned indicium")

      sign_in_as(create_admin)
      get letter_path(letter)
      expect(response.body).to include("Clear orphaned indicium")
    end
  end
end
