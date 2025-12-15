require "test_helper"

class USPS::FLIRTEngineTest < ActiveSupport::TestCase
  test "metered letter rates match pricing engine" do
    assert_equal 0.73, USPS::FLIRTEngine.metered_price(:letter, 1.0)
    assert_equal 1.02, USPS::FLIRTEngine.metered_price(:letter, 2.0)
    assert_equal 1.31, USPS::FLIRTEngine.metered_price(:letter, 3.0)
    assert_equal 1.60, USPS::FLIRTEngine.metered_price(:letter, 3.5)
  end

  test "stamp letter rates for 2024" do
    assert_equal 0.78, USPS::FLIRTEngine.stamp_price(:letter, 1.0)
    assert_equal 1.08, USPS::FLIRTEngine.stamp_price(:letter, 2.0)
    assert_equal 1.38, USPS::FLIRTEngine.stamp_price(:letter, 3.0)
    assert_equal 1.68, USPS::FLIRTEngine.stamp_price(:letter, 3.5)
  end

  test "desired price for international mail" do
    assert_equal 1.75, USPS::FLIRTEngine.desired_price(:letter, 1.0, "CA")
    assert_equal 1.75, USPS::FLIRTEngine.desired_price(:letter, 1.0, "MX")
    assert_equal 1.75, USPS::FLIRTEngine.desired_price(:letter, 1.0, "GB")
  end

  test "closest us price calculation" do
    # Test finding the closest US rate for international rate
    result = USPS::FLIRTEngine.closest_us_price(1.75)
    
    assert result[:processing_category] == :letter || result[:processing_category] == :flat
    assert result[:price] >= 1.75
    assert result[:difference] >= 0
  end

  test "engines have consistent rates" do
    # Test that both engines return the same rates
    assert_equal USPS::PricingEngine.metered_price(:letter, 1.0), 
                 USPS::FLIRTEngine.metered_price(:letter, 1.0)
    
    assert_equal USPS::PricingEngine.metered_price(:flat, 1.0), 
                 USPS::FLIRTEngine.metered_price(:flat, 1.0)
  end

  test "non-machinable surcharge consistency" do
    normal_price = USPS::FLIRTEngine.metered_price(:letter, 1.0)
    non_mach_price = USPS::FLIRTEngine.metered_price(:letter, 1.0, true)
    
    assert_equal 0.48, non_mach_price - normal_price
  end
end