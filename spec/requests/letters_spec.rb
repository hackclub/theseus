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

  it "can clear every tag on a letter" do
    letter.update!(tags: [ "keep" ])

    get edit_letter_path(letter)
    expect(response.body).to include('<input type="hidden" name="letter[tags][]" value="">')

    patch letter_path(letter), params: { letter: { tags: [ "" ] } }
    expect(letter.reload.tags).to eq([])
  end

  describe "return addresses" do
    let(:someone_else) { create(:return_address, user: create(:user), shared: false) }
    let(:shared) { create(:return_address, shared: true) }

    it "refuses to set another user's private return address" do
      patch letter_path(letter), params: { letter: { return_address_id: someone_else.id } }

      expect(flash[:alert]).to include("isn't available to you")
      expect(letter.reload.return_address_id).not_to eq(someone_else.id)
    end

    it "accepts a shared return address" do
      patch letter_path(letter), params: { letter: { return_address_id: shared.id } }

      expect(letter.reload.return_address_id).to eq(shared.id)
    end

    it "refuses to create a letter with another user's private return address" do
      expect {
        post letters_path, params: {
          letter: {
            return_address_id: someone_else.id,
            height: 4.125, width: 9.5, weight: 1, processing_category: "letter",
            usps_mailer_id_id: user.home_mid_id,
            address_attributes: { first_name: "A", line_1: "1 St", city: "B", state: "VT", postal_code: "05401", country: "US" }
          }
        }
      }.not_to change(Letter, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
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

  describe "creating a letter" do
    it "creates a new letter via POST with address params, template, and tags" do
      return_address = create(:return_address, user: user)

      expect {
        post letters_path, params: {
          letter: {
            height: 4.125,
            width: 9.5,
            weight: 1,
            processing_category: "letter",
            postage_type: "stamps",
            usps_mailer_id_id: user.home_mid_id,
            return_address_id: return_address.id,
            tags: [ "invoice", "billing" ],
            body: "Test body content",
            address_attributes: {
              first_name: "John",
              last_name: "Doe",
              line_1: "123 Main St",
              city: "Burlington",
              state: "VT",
              postal_code: "05401",
              country: "US"
            }
          }
        }
      }.to change(Letter, :count).by(1)

      created_letter = Letter.last
      expect(response).to redirect_to(letter_path(created_letter))
      expect(created_letter.tags).to eq([ "invoice", "billing" ])
      expect(created_letter.body).to eq("Test body content")
      expect(created_letter.address.first_name).to eq("John")
      expect(created_letter.return_address_id).to eq(return_address.id)
    end
  end

  describe "editing a letter" do
    it "updates letter with changed template and rubber stamps" do
      letter.update!(body: "Original body")

      patch letter_path(letter), params: {
        letter: {
          body: "Updated body",
          rubber_stamps: "stamp text"
        }
      }

      expect(response).to redirect_to(letter_path(letter))
      expect(letter.reload.body).to eq("Updated body")
      expect(letter.reload.rubber_stamps).to eq("stamp text")
    end
  end

  describe "letter state transitions" do
    it "marks a letter as printed via POST mark_printed_letter_path" do
      post mark_printed_letter_path(letter)

      expect(response).to redirect_to(letter_path(letter))
      expect(letter.reload.aasm_state).to eq("printed")
    end

    it "marks a letter as mailed via POST mark_mailed_letter_path and changes aasm_state" do
      letter.mark_printed!

      post mark_mailed_letter_path(letter)

      expect(response).to redirect_to(letter_path(letter))
      expect(letter.reload.aasm_state).to eq("mailed")
    end

    it "refuses to mark an already-mailed letter as mailed again" do
      letter.mark_printed!
      letter.mark_mailed!

      post mark_mailed_letter_path(letter)

      expect(response).to redirect_to(letter_path(letter))
      expect(flash[:alert]).to include("already marked as mailed")
    end
  end

  describe "deleting a letter" do
    it "deletes a letter via DELETE as admin" do
      admin = create_admin
      sign_in_as(admin)
      standalone = create(:letter, user: admin, batch: nil)
      letter_id = standalone.id

      delete letter_path(standalone)

      expect(response.status).to be_in([302, 303])
      expect { Letter.find(letter_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "letter index" do
    it "GET letters_path renders the index" do
      letter # trigger creation
      create(:letter, user: user, batch: nil)

      get letters_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Letters")
    end

    it "filters letters by status parameter" do
      letter.mark_printed!
      unprinted = create(:letter, user: user, batch: nil)

      get letters_path, params: { status: "printed" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(letter_path(letter))
      expect(response.body).not_to include(letter_path(unprinted))
    end

    it "supports pagination on the index" do
      # Create enough letters to require pagination (more than 25)
      26.times { create(:letter, user: user, batch: nil) }

      get letters_path, params: { page: 1 }
      expect(response).to have_http_status(:ok)

      get letters_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
    end
  end
end
