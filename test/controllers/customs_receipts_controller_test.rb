require "test_helper"

class CustomsReceiptsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get customs_receipts_index_url
    assert_response :success
  end

  test "should get show" do
    get customs_receipts_show_url
    assert_response :success
  end
end
