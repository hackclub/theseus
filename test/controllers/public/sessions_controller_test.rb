require "test_helper"

class Public::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get send_email" do
    get public_sessions_send_email_url
    assert_response :success
  end
end
