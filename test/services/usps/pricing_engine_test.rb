require "test_helper"

class USPS::PricingEngineTest < ActiveSupport::TestCase
  test "metered letter rates for 2024" do
    assert_equal 0.73, USPS::PricingEngine.metered_price(:letter, 1.0)
    assert_equal 1.02, USPS::PricingEngine.metered_price(:letter, 2.0)
    assert_equal 1.31, USPS::PricingEngine.metered_price(:letter, 3.0)
    assert_equal 1.60, USPS::PricingEngine.metered_price(:letter, 3.5)
  end

  test "stamp letter rates for 2024" do
    assert_equal 0.78, USPS::PricingEngine.domestic_stamp_price(:letter, 1.0)
    assert_equal 1.08, USPS::PricingEngine.domestic_stamp_price(:letter, 2.0)
    assert_equal 1.38, USPS::PricingEngine.domestic_stamp_price(:letter, 3.0)
    assert_equal 1.68, USPS::PricingEngine.domestic_stamp_price(:letter, 3.5)
  end

  test "flat rates for 2024" do
    assert_equal 1.55, USPS::PricingEngine.metered_price(:flat, 1.0)
    assert_equal 1.83, USPS::PricingEngine.metered_price(:flat, 2.0)
    assert_equal 2.11, USPS::PricingEngine.metered_price(:flat, 3.0)
  end

  test "international letter rates for 2024" do
    assert_equal 1.75, USPS::PricingEngine.fcmi_price(:letter, 1.0, "CA")
    assert_equal 1.75, USPS::PricingEngine.fcmi_price(:letter, 1.0, "MX")
    assert_equal 1.75, USPS::PricingEngine.fcmi_price(:letter, 1.0, "GB")
    
    assert_equal 2.65, USPS::PricingEngine.fcmi_price(:letter, 2.0, "MX")
    assert_equal 3.16, USPS::PricingEngine.fcmi_price(:letter, 2.0, "GB")
  end

  test "non-machinable surcharge for 2024" do
    normal_price = USPS::PricingEngine.metered_price(:letter, 1.0)
    non_mach_price = USPS::PricingEngine.metered_price(:letter, 1.0, true)
    
    assert_equal 0.48, non_mach_price - normal_price
    assert_equal 1.21, non_mach_price
  end

  test "stamp price helper method" do
    # Test US domestic
    assert_equal 0.78, USPS::PricingEngine.stamp_price(:letter, 1.0, "US")
    
    # Test international
    assert_equal 1.75, USPS::PricingEngine.stamp_price(:letter, 1.0, "CA")
    assert_equal 1.75, USPS::PricingEngine.stamp_price(:letter, 1.0, "MX")
  end

  test "invalid weight raises error" do
    assert_raises(ArgumentError) do
      USPS::PricingEngine.metered_price(:letter, 4.0)
    end
  end

  test "invalid type raises error" do
    assert_raises(ArgumentError) do
      USPS::PricingEngine.metered_price(:package, 1.0)
    end
  end
end