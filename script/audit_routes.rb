admin = User.find_by(is_admin: true)
abort "No admin user found!" unless admin
puts "Auditing as #{admin.username}..."

app = Rails.application
session = ActionDispatch::Integration::Session.new(app)
session.reset!

# Establish session - hit root, then dev_login
session.get "/back_office"
session.get "/back_office/dev_login" if Rails.env.development?

skip_pattern = /rails|active_storage|good_job|blazer|flipper|letter_opener|pwa|cable|\.js|\.css/

routes = app.routes.routes.select { |r|
  r.verb == "GET" &&
    r.defaults[:controller].present? &&
    r.path.spec.to_s.exclude?("*") &&
    !r.path.spec.to_s.match?(skip_pattern)
}

def sample_for(ctrl)
  case ctrl
  when /admin\/users/ then User.first&.to_param
  when /admin\/common_tags/ then CommonTag.first&.id
  when /admin\/usps\/mailer_ids/ then USPS::MailerId.first&.id
  when /admin\/usps\/payment_accounts/ then USPS::PaymentAccount.first&.id
  when /warehouse\/orders/ then Warehouse::Order.first&.hc_id
  when /warehouse\/templates/ then Warehouse::Template.first&.id
  when /warehouse\/purchase_orders/ then Warehouse::PurchaseOrder.first&.id
  when /warehouse\/sku_requests/ then Warehouse::SKURequest.first&.id
  when /warehouse\/skus/ then Warehouse::SKU.first&.id
  when /warehouse\/batches/ then Warehouse::Batch.first&.id
  when /letter\/batches/ then Letter::Batch.first&.id
  when /letter\/queues/ then Letter::Queue.first&.id
  when /letter\/instant_queues/ then Letter::InstantQueue.first&.id
  when /^letters/ then Letter.first&.to_param
  when /api_keys/ then APIKey.first&.id
  when /return_addresses/ then ReturnAddress.first&.id
  when /billing/ then LedgerEntry.first&.id
  when /hcb\/payment_accounts/ then BillingProfile.first&.id
  when /inspect\/iv_mtr/ then USPS::IVMTR::Event.first&.public_id
  when /inspect\/indicia/ then USPS::Indicium.first&.public_id
  when /tags/ then "example"
  end
end

ok = []
errors = []
skipped = []

routes.each do |route|
  path = route.path.spec.to_s.gsub("(.:format)", "")
  ctrl = route.defaults[:controller].to_s
  action = route.defaults[:action].to_s

  if path.include?(":id") || path.include?(":slug") || path.include?(":cron_key") || path.include?(":public_id")
    id = sample_for(ctrl)
    if id.nil?
      skipped << "#{path} (no record for #{ctrl})"
      next
    end
    path = path.gsub(/:id|:slug|:cron_key|:public_id/, id.to_s)
  end

  if path.include?(":")
    skipped << "#{path} (unresolved param)"
    next
  end
  # Test the base path, plus common query param variations for index routes
  paths_to_test = [path]
  if action == "index"
    user_id = User.first&.id
    paths_to_test << "#{path}?user_id=#{user_id}" if user_id
    paths_to_test << "#{path}?search=test"
    paths_to_test << "#{path}?state=draft"
    paths_to_test << "#{path}?origin=manual"
    paths_to_test << "#{path}?page=1"
  end

  paths_to_test.each do |test_path|
    begin
      session.get test_path
      status = session.response.status
      if status >= 500
        body = session.response.body.to_s
        err = body.match(/<h1>(.*?)<\/h1>/m)&.[](1)&.strip || "HTTP #{status}"
        errors << "#{status} #{test_path} — #{err}"
      else
        ok << test_path
      end
    rescue => e
      errors << "EXC #{test_path} — #{e.class}: #{e.message[0..150]}"
    end
  end
end

puts "\n=== #{ok.size} OK, #{errors.size} ERRORS, #{skipped.size} SKIPPED ==="
if errors.any?
  puts "\nERRORS:"
  errors.each { |e| puts "  #{e}" }
end
if skipped.any?
  puts "\nSKIPPED:"
  skipped.each { |s| puts "  #{s}" }
end
