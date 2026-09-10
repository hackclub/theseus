# frozen_string_literal: true

require "rails_helper"

# The map page is the only thing standing between a customer's CSV and the
# importer, and every one of these headers has shown up in a real upload.
RSpec.describe "the CSV map page" do
  let(:user) { create(:user, can_warehouse: true) }
  let(:template) { Warehouse::Template.create!(name: "Sticker pack", user: user, public: true) }

  def render_map(view_class, controller_class, batch, headers, sample_row)
    controller = controller_class.new
    controller.request = ActionDispatch::TestRequest.create
    allow(controller).to receive(:current_user).and_return(user)
    controller.view_context.render(view_class.new(batch: batch, csv_headers: headers, sample_row: sample_row))
  end

  def render_warehouse(headers, sample_row = nil, batch: create(:warehouse_batch, user: user, warehouse_template: template))
    render_map(Views::Warehouse::Batches::Map, Warehouse::BatchesController, batch, headers, sample_row)
  end

  it "auto-maps the header spellings the old mapper knew" do
    headers = [ "Address (Line 1)", "Zip / Postal Code", "Recipient Name", "Login Email", "addressline1", "State/Province", "Address (City)" ]
    html = render_warehouse(headers)

    expect(html).to include(%(<select name="field_mapping[Address (Line 1)]" class="w-100">))
    expect(html).to include(%(<option value="line_1" selected>))
    expect(html).to include(%(<option value="postal_code" selected>))
    expect(html).to include(%(<option value="first_name" selected>))
    expect(html).to include(%(<option value="email" selected>))
    expect(html).to include(%(<option value="state" selected>))
    expect(html).to include(%(<option value="city" selected>))
  end

  it "warns about required fields no column matched" do
    html = render_warehouse([ "first_name", "email" ])
    expect(html).to include("No column matched these required fields").and include("City").and include("ZIP / Postal Code")
    expect(html).not_to include("<li>Email</li>")
  end

  it "renders a header-only CSV without a sample row" do
    expect { render_warehouse([ "first_name", "city" ], nil) }.not_to raise_error
  end

  it "skips blank headers so rack doesn't 400 on field_mapping[]" do
    html = render_warehouse([ "first_name", "", nil, "city" ])
    expect(html).not_to include(%(name="field_mapping[]"))
    expect(html).to include("Your CSV has 2 columns")
  end

  it "keeps brackets out of the field names it submits" do
    html = render_warehouse([ "Address[1]" ])
    expect(html).to include(%(name="field_mapping[Address1]"))
  end

  it "offers rubber stamps on letter batches only" do
    letter_batch = create(:letter_batch, user: user)
    letter_html = render_map(Views::Letter::Batches::Map, Letter::BatchesController, letter_batch, [ "Rubber Stamps" ], nil)
    expect(letter_html).to include(%(<option value="rubber_stamps" selected>))

    expect(render_warehouse([ "Rubber Stamps" ])).not_to include("rubber_stamps")
  end
end
