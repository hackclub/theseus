class USPS::IVMTR::ImportEventsJob < ApplicationJob
  queue_as :default

  MAPPING = {
    "scanDatetime" => :happened_at,
    "scanEventCode" => :opcode,
    "scanFacilityZip" => :zip_code
  }

  def perform(batch)
    mids = batch.payload.filter_map { |e| e["imbMid"] }.uniq
    mailer_ids_by_mid = USPS::MailerId.where(mid: mids).index_by(&:mid)

    ActiveRecord::Base.transaction do
      batch.payload.each do |event|
        imb_mid = event["imbMid"]
        mailer_id = mailer_ids_by_mid[imb_mid]

        USPS::IVMTR::Event.find_or_create_from_payload(
          event,
          batch.id,
          mailer_id.id
        )
      end

      batch.update!(processed: true)
    end
  end
end
