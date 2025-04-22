require "test_helper"

class USPS::IVMTR::WebhookControllerTest < ActionDispatch::IntegrationTest
  setup do
    @webhook_password = "test_password"
    Rails.application.credentials.stubs(:dig).with(:usps, :iv_mtr, :webhook_password).returns(@webhook_password)
  end

  test "requires authentication" do
    post usps_iv_mtr_webhook_url, params: { events: [], msgGrpId: "123" }
    assert_response :unauthorized
  end

  test "creates batch and enqueues import job" do
    events = [
      {
        "imbMid" => "123456",
        "imbSerialNumber" => "789",
        "scanDatetime" => "2024-03-15T12:00:00Z",
        "scanEventCode" => "10",
        "scanFacilityZip" => "12345"
      }
    ]

    assert_difference -> { USPS::IVMTR::RawJSONBatch.count } => 1 do
      assert_enqueued_with(job: USPS::IVMTR::ImportEventsJob) do
        post usps_iv_mtr_webhook_url,
          params: { events: events, msgGrpId: "123" },
          headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("my_best_friend_the_informed_visibility_robot", @webhook_password) }
      end
    end

    assert_response :success
    batch = USPS::IVMTR::RawJSONBatch.last
    assert_equal events, batch.payload
    assert_equal "123", batch.message_group_id
    assert_not batch.processed?
  end
end
