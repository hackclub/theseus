# frozen_string_literal: true

require "rails_helper"

# app/frontend/js/turbo-confirm.js reads data-turbo-confirm/data-confirm off the
# submitted <form>, its submitter button, or a clicked <a>. These assert the
# markup actually carries the attribute on the element the shim inspects.
RSpec.describe "confirm attributes", type: :request do
  let(:admin) { create_admin }

  before do
    fake_hcb!
    sign_in_as(admin)
  end

  it "puts data-turbo-confirm on the form for form_with data: { turbo_confirm: }" do
    queue = Letter::Queue.new(
      user: admin, name: "Confirmed", slug: "confirmed",
      letter_height: 1, letter_width: 1, letter_weight: 1,
      letter_mailer_id: admin.home_mid, letter_return_address: admin.home_return_address,
      letter_processing_category: 0
    ).tap { |q| q.save!(validate: false) }

    get letter_queue_path(queue)

    expect(response.body).to match(/<form[^>]*data-turbo-confirm="Delete this queue\?"/)
  end

  it "puts data-confirm on the button for button_to data: { confirm: }" do
    sku = create(:warehouse_sku)
    purchase_order = Warehouse::PurchaseOrder.new(user: admin, supplier_name: "acme").tap do |po|
      po.line_items.build(sku: sku, quantity: 1, unit_cost: 1)
      po.save!(validate: false)
    end

    get warehouse_purchase_order_path(purchase_order)

    expect(response.body).to match(/<button[^>]*data-confirm="Submit this purchase order for approval\?"/)
  end

  it "puts data-turbo-confirm on the submit button when the button carries it" do
    letter = create(:letter, user: admin, batch: nil)
    letter.update_columns(aasm_state: "pending")

    get letter_path(letter)

    expect(response.body).to match(/<button[^>]*data-turbo-confirm="Delete this letter\?"/)
  end
end
