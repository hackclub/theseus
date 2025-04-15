require "test_helper"

class USPS::IVMTR::ImportEventsJobTest < ActiveJob::TestCase
  setup do
    @mailer_id = USPS::MailerId.create!(mid: "123456", crid: "CR123")
    @letter = Letter.create!(
      usps_mailer_id: @mailer_id,
      imb_serial_number: 789,
      address: Address.create!(
        street_address: "123 Main St",
        city: "Anytown",
        state: "CA",
        postal_code: "12345"
      )
    )
  end

  test "processes events and creates tracking records" do
    batch = USPS::IVMTR::RawJSONBatch.create!(
      payload: [
        {
          "imbMid" => "123456",
          "imbSerialNumber" => "789",
          "scanDatetime" => "2024-03-15T12:00:00Z",
          "scanEventCode" => "10",
          "scanFacilityZip" => "12345"
        }
      ],
      processed: false
    )

    assert_difference -> { USPS::IVMTR::Event.count } => 1 do
      USPS::IVMTR::ImportEventsJob.perform_now(batch)
    end

    event = USPS::IVMTR::Event.last
    assert_equal batch.id, event.batch_id
    assert_equal @letter.id, event.letter_id
    assert_equal @mailer_id.id, event.mailer_id_id
    assert_equal "2024-03-15T12:00:00Z".to_datetime, event.happened_at
    assert_equal "10", event.opcode
    assert_equal "12345", event.zip_code
    assert batch.reload.processed?
  end

  test "handles events with unknown mailer IDs" do
    batch = USPS::IVMTR::RawJSONBatch.create!(
      payload: [
        {
          "imbMid" => "999999", # Unknown mailer ID
          "imbSerialNumber" => "789",
          "scanDatetime" => "2024-03-15T12:00:00Z",
          "scanEventCode" => "10",
          "scanFacilityZip" => "12345"
        }
      ],
      processed: false
    )

    assert_raises ActiveRecord::RecordNotFound do
      USPS::IVMTR::ImportEventsJob.perform_now(batch)
    end
  end
end
