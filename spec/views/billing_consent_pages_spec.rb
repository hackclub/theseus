# frozen_string_literal: true

require "rails_helper"

# Renders every page that carries a money notice with a real controller
# context, so a broken helper or missing route fails here and not in prod.
RSpec.describe "billing consent pages" do
  let(:mailer_id) { create(:usps_mailer_id) }
  let(:return_address) { create(:return_address) }
  let(:user) { create(:user, can_warehouse: true, can_use_indicia: true, home_mid: mailer_id, home_return_address: return_address) }
  let(:profile) { create(:billing_profile, user: user, organization_name: "Clubs") }
  let(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0) }
  let(:template) { Warehouse::Template.create!(name: "Sticker pack", user: user, public: true).tap { |t| t.line_items.create!(sku: sku, quantity: 1) } }

  before do
    fake_hcb!
    profile
    allow(Billing::Balance).to receive(:cents_for).and_return(50_000)
  end

  def render_action(controller_class, action, assigns = {})
    controller = controller_class.new
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new
    allow(controller).to receive(:current_user).and_return(user)
    assigns.each { |k, v| controller.instance_variable_set("@#{k}", v) }
    controller.render_to_string(action, layout: false)
  end

  def render_view(controller_class, view)
    controller = controller_class.new
    controller.request = ActionDispatch::TestRequest.create
    allow(controller).to receive(:current_user).and_return(user)
    controller.view_context.render(view)
  end

  it "buy indicia page and the letter sidebar form" do
    letter = create(:letter, user: user, usps_mailer_id: mailer_id, return_address: return_address, postage_type: "indicia", batch: nil)
    html = render_action(LettersController, :buy_indicia, letter: letter)
    expect(html).to include("Billing notice").and include("Clubs").and include("Buy Indicia").and include(letter.public_id)

    html = render_action(LettersController, :show, letter: letter)
    expect(html).to include("billing-consent-sidebar")
  end

  it "letter batch process form and its refreshable consent fragment" do
    batch = create(:letter_batch, user: user, mailer_id: mailer_id, letter_mailing_date: 1.week.from_now.to_date)
    create(:letter, user: user, batch: batch, usps_mailer_id: mailer_id, return_address: return_address, postage_type: "indicia", mailing_date: batch.letter_mailing_date)
    html = render_view(Letter::BatchesController, Views::Letter::Batches::Process.new(batch: batch))
    expect(html).to include("billing-consent-frame").and include("Start Processing").and include("batch[hcb_payment_account_id]")
    expect(html).to include("/back_office/letter/batches/#{batch.to_param}/billing_consent")

    controller = Letter::BatchesController.new
    allow(controller).to receive(:current_user).and_return(user)
    request = ActionDispatch::TestRequest.create("QUERY_STRING" => "us_postage_type=stamps&intl_postage_type=indicia&non_machinable=1")
    request.path_parameters = { controller: "letter/batches", action: "billing_consent", id: batch.to_param }
    controller.dispatch(:billing_consent, request, ActionDispatch::TestResponse.new)
    expect(controller.response.body).to include("money-notice").and include("Start Processing")
  end

  it "warehouse order page bills labor now and postage later" do
    order = Warehouse::Order.from_template(template, user: user, recipient_email: "a@b.c", address: create(:address, country: "US"), billing_profile: profile)
    order.save!
    html = render_action(Warehouse::OrdersController, :show, warehouse_order: order)
    expect(html).to include("Billing notice").and include("$2.00").and include("later").and include("Send to Warehouse")
  end

  it "warehouse batch process form picks the payer" do
    batch = Warehouse::Batch.create!(user: user, warehouse_template: template)
    batch.addresses.create!(create(:address).attributes.except("id", "created_at", "updated_at"))
    html = render_view(Warehouse::BatchesController, Views::Warehouse::Batches::Process.new(batch: batch))
    expect(html).to include("Billing notice").and include("Process Batch").and include("batch[hcb_payment_account_id]").and include("labor for 1 order")
  end

  it "instant queue settings say who pays" do
    allow(USPS::PricingEngine).to receive(:metered_price).and_return(0.73)
    queue = Letter::InstantQueue.create!(user: user, name: "q", slug: "q", template: "x", postage_type: "indicia", letter_height: 4, letter_width: 6, letter_weight: 1,
      letter_processing_category: 0, letter_mailer_id: mailer_id, letter_return_address: return_address, tags: [ "t" ],
      usps_payment_account: create(:usps_payment_account, usps_mailer_id: mailer_id), billing_profile: profile)
    html = render_view(Letter::InstantQueuesController, Views::Letter::InstantQueues::Show.new(queue: queue, letters: Letter.none, batches: [], letter_counts: {}, search: nil, status: nil))
    expect(html).to include("Clubs is billed $0.73")
  end
end
