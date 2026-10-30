# frozen_string_literal: true

# Letters price themselves on save through USPS::PricingEngine, which calls the
# live USPS API. Give every spec flat rates instead so the suite never touches
# the network. Specs that care about a rate can still stub over these.
RSpec.configure do |config|
  config.before do
    allow(USPS::PricingEngine).to receive(:metered_price).and_return(0.73)
    allow(USPS::PricingEngine).to receive(:domestic_stamp_price).and_return(0.78)
    allow(USPS::PricingEngine).to receive(:fcmi_price).and_return(1.65)
  end
end
