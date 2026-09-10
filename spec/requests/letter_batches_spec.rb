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

  it "keeps every template the process form selected" do
    templates = SnailMail::PhlexService.templates_for_size(:standard).first(3)

    post process_letter_batch_path(batch), params: {
      batch: {
        letter_mailing_date: Date.current.iso8601,
        us_postage_type: "stamps",
        intl_postage_type: "stamps",
        template_cycle: templates
      }
    }

    expect(batch.reload.process_options["template_cycle"]).to eq(templates)
  end

  it "does not put a submit button in the regenerate form's cancel link" do
    get regenerate_form_letter_batch_path(batch)

    expect(response.body).not_to include("<button>Cancel</button>")
  end

  it "points the template picker's select-one guard at its own form" do
    get regenerate_form_letter_batch_path(batch)

    expect(response.body).to include('class="template-picker"')
    expect(response.body).to include("picker.closest('form')")
  end

  it "regenerates labels when the skip-failed button posts no batch params" do
    post regenerate_labels_letter_batch_path(batch)

    expect(response).to redirect_to(letter_batch_path(batch))
  end

  describe "the edit form" do
    it "offers the title and tags, plus specs while the batch can still be processed" do
      batch.update_columns(aasm_state: "fields_mapped")

      get edit_letter_batch_path(batch)

      expect(response.body).to include('name="letter_batch[user_facing_title]"')
      expect(response.body).to include('name="letter_batch[letter_return_address_id]"')
      expect(response.body).not_to include("<button>Cancel</button>")
    end

    it "hides the specs once the batch is processed" do
      batch.update_columns(aasm_state: "processed")

      get edit_letter_batch_path(batch)

      expect(response.body).to include('name="letter_batch[user_facing_title]"')
      expect(response.body).not_to include('name="letter_batch[letter_return_address_id]"')
    end
  end

  describe "picklist bulk actions" do
    let(:processed) do
      create(:letter_batch, user: user).tap { |b| b.update_columns(aasm_state: "processed") }
    end
    let!(:letters) { Array.new(3) { create(:letter, batch: processed, user: user) } }

    it "marks only the picked letters mailed" do
      post mark_mailed_letter_batch_path(processed), params: { letter_ids: letters.first(2).map(&:id).join(",") }

      expect(response).to redirect_to(letter_batch_path(processed))
      expect(letters.map { |l| l.reload.aasm_state }).to eq(%w[mailed mailed pending])
    end

    it "still marks every letter mailed when nothing is picked" do
      post mark_mailed_letter_batch_path(processed)

      expect(letters.map { |l| l.reload.aasm_state }).to all(eq("mailed"))
    end

    it "marks every picked letter printed, not just the first" do
      post confirm_printed_letter_batch_path(processed), params: { letter_ids: letters.map(&:id).join(",") }

      expect(letters.map { |l| l.reload.aasm_state }).to all(eq("printed"))
    end

    it "gives QZ a #mark_printed button and an instant print window" do
      processed.pdf_label.attach(io: StringIO.new("%PDF-1.4"), filename: "labels.pdf", content_type: "application/pdf")

      get letter_batch_path(processed)

      expect(response.body).to include('id="mark_printed"')
      expect(response.body).to include("instant_print_root")
    end

    it "renders the picklist for a processed batch" do
      get letter_batch_path(processed)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("data-letter-id=\"#{letters.first.id}\"")
    end

    it "prints every picked letter, not just the first" do
      post print_subset_letter_batch_path(processed), params: { letter_ids: letters.map(&:id).join(",") }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("3letters.pdf")
    end
  end
end
