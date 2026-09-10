# frozen_string_literal: true

require "rails_helper"

# Every GET page in the app, rendered once as an admin with one of everything
# in the database. This exists because the views were rewritten wholesale and
# nothing else in the suite opens most of them.
RSpec.describe "every page renders", type: :request do
  SKIP = %r{
    ^/(rails/|good_job|blazer|flipper|mcp|up$|\.well-known|api/|auth/)
    | callback | dev_login | /impersonate
    | /qz_tray/cert   # reads the QZ signing cert from QZ_CERTS_PATH
  }x

  let(:admin) { create_admin }

  # Records to stand in for :id, keyed by route prefix. Routes with a :id whose
  # prefix isn't here are skipped.
  def records
    profile = create(:billing_profile, user: admin)
    sku = create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0)
    template = Warehouse::Template.create!(name: "Sticker pack", user: admin, public: true).tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
    letter_batch = create(:letter_batch, user: admin).tap { |b| b.update_columns(tags: [ "smoke" ]) }
    warehouse_batch = create(:warehouse_batch, user: admin, warehouse_template: template)
    order = Warehouse::Order.from_template(template, user: admin, recipient_email: "a@b.c", address: create(:address, country: "US"), billing_profile: profile).tap(&:save!)
    purchase_order = Warehouse::PurchaseOrder.new(user: admin, supplier_name: "acme").tap { |po| po.line_items.build(sku: sku, quantity: 1, unit_cost: 1); po.save!(validate: false) }
    sku_request = Warehouse::SKURequest.new(user: admin, name: "thing", description: "d", category: Warehouse::SKU.categories.keys.first, unit_cost: 1, country_of_origin: "US", expected_arrival: Date.tomorrow, expected_quantity: 1, program: "p").tap { |r| r.save!(validate: false) }
    queue = Letter::Queue.new(user: admin, name: "Smoke", letter_height: 1, letter_width: 1, letter_weight: 1, letter_mailer_id: admin.home_mid, letter_return_address: admin.home_return_address, letter_processing_category: 0, tags: [ "smoke" ], slug: "smoke").tap { |q| q.save!(validate: false) }
    instant_queue = Letter::InstantQueue.new(user: admin, name: "Smoke instant", template: "hackatime_template", postage_type: "stamps", slug: "smoke-instant").tap { |q| q.save!(validate: false) }
    api_key = APIKey.create!(user: admin, billing_profile: profile)

    {
      "/back_office/admin/users/:id" => admin.id,
      "/back_office/admin/usps/mailer_ids/:id" => admin.home_mid_id,
      "/back_office/admin/usps/payment_accounts/:id" => create(:usps_payment_account).id,
      "/back_office/hcb/payment_accounts/:id" => profile.id,
      "/back_office/billing/:id" => profile.id,
      "/back_office/letter/batches/:id" => letter_batch.id,
      "/back_office/letters/:id" => create(:letter).id,
      "/back_office/return_addresses/:id" => admin.home_return_address_id,
      "/back_office/warehouse/skus/:id" => sku.id,
      "/back_office/warehouse/templates/:id" => template.id,
      "/back_office/warehouse/batches/:id" => warehouse_batch.id,
      "/back_office/warehouse/orders/:id" => order.hc_id,
      "/back_office/warehouse/purchase_orders/:id" => purchase_order.id,
      "/back_office/warehouse/sku_requests/:id" => sku_request.id,
      "/back_office/letter/queues/:id" => queue.slug,
      "/back_office/letter/instant_queues/:id" => instant_queue.slug,
      "/back_office/api_keys/:id" => api_key.id,
      "/back_office/tags/:id" => "smoke",
      "/packages/:id" => order.public_id
    }
  end

  def get_paths(records)
    Rails.application.routes.routes.filter_map do |route|
      next unless route.verb == "GET" && route.defaults[:controller]
      path = route.path.spec.to_s.sub("(.:format)", "")
      next if path.match?(SKIP)
      next path unless path.include?(":")

      prefix, id = records.find { |k, _| path.start_with?(k) }
      next if prefix.nil? || path.delete_prefix(prefix).include?(":")
      path.sub(":id", id.to_s)
    end.uniq
  end

  it "does not raise or 500 on any GET route as an admin" do
    fake_hcb!
    sign_in_as(admin)
    paths = get_paths(records)
    expect(paths.size).to be > 100

    failures = paths.filter_map do |path|
      get path
      "#{path} => #{response.status}" if response.status >= 500
    rescue Exception => e
      "#{path} => #{e.class}: #{e.message.lines.first&.strip}"
    end

    expect(failures).to eq([]), failures.join("\n")
  end
end
