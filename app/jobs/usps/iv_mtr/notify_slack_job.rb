class USPS::IVMTR::NotifySlackJob < ApplicationJob
  queue_as :default

  def perform(event)
    return unless event

    message = format_slack_message(event)
    post_to_slack(message)
  end

  private

  def format_slack_message(event)

    e = event.hydrated

    [
                {
                    "type": "context",
                    "elements": [
                        {
                            "type": "mrkdwn",
                            "text": if event.bogon?
                              ":neocat_laptop_notice: hey <@U06QK6AG3RD>! we got a bogon! #{event.imb_serial_number} on #{event.mailer_id.id} @ <!date^#{event.happened_at.to_i}^{date_num} {time_secs}|#{event.happened_at.iso8601}>??"
                            else
                              ":mailbox_with_mail: new IV event for *Letter #{event.letter.imb_serial_number}/#{event.letter.imb_rollover_count} on #{event.letter.usps_mailer_id.id}* @ <!date^#{event.happened_at.to_i}^{date_num} {time_secs}|#{event.happened_at.iso8601}>!"
                            end
                        }
                    ]
                },
                {
                    "type": "context",
                    "elements": [
                        {
                            "type": "mrkdwn",
                            "text": "[OP#{e.opcode.code}] *#{e.opcode.process_description}*\n_#{e.handling_event_type_description} – #{e.mail_phase} – #{e.machine_name} (#{event.payload.dig("machineId") || "no ID"})_"
                        }
                    ]
                },
                {
                    "type": "context",
                    "elements": [
                        {
                            "type": "mrkdwn",
                            "text": "in #{e.scan_facility_name} (#{e.scan_locale_key}) @ #{e.scan_facility_city}, #{e.scan_facility_state} #{e.scan_facility_zip}"
                        }
                    ]
                },
                {
                    "type": "context",
                    "elements": [
                        {
                            "type": "plain_text",
                            "text": "#{event.hydrated.opcode.machine_type} / #{event.hydrated.opcode.equipment_description} (iid #{event.public_id})",
                        }
                    ]
                }
            ]
    
  end

  def post_to_slack(message)
    Slack::Notifier.new ENV.fetch("IV_MTR_WEBHOOK_URL") do
      defaults channel: "#ivmtr-feed", username: "iv-mtr"
    end.ping blocks: message
  end
end 