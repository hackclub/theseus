class USPS::IVMTR::ImportEventsJob < ApplicationJob
  queue_as :default

  MAPPING = {
    "scanDatetime" => :happened_at,
    "scanEventCode" => :opcode,
    "scanFacilityZip" => :zip_code
  }

  def perform(batch)
    ActiveRecord::Base.transaction do
      batch.payload.each do |event|
        # Extract the mailer ID from the IMB
        imb_mid = event["imbMid"]
        mailer_id = USPS::MailerId.find_by(mid: imb_mid)
        
        # Find or create the event
        USPS::IVMTR::Event.find_or_create_from_payload(
          event,
          batch.id,
          mailer_id.id
        )
      end
      
      # Mark the batch as processed
      batch.update!(processed: true)
    end
  end
end
