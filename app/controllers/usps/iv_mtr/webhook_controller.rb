# frozen_string_literal: true

module USPS
  module IVMTR
    class WebhookController < ActionController::Base
      skip_before_action :verify_authenticity_token

      before_action do
        http_basic_authenticate_or_request_with(
          name: "my_best_friend_the_informed_visibility_robot",
          password: Rails.application.credentials.dig(:usps, :iv_mtr, :webhook_password),
          realm: "IV-MTR",
          message: "nice try, jackwagon"
        )
      end

      def ingest
        data = begin
          JSON.parse(request.raw_post)
        rescue JSON::ParserError
          nil
        end

        return render json: { error: "that isn't a JSON object" }, status: :bad_request unless data.is_a?(Hash)

        events = data["events"]
        return render json: { error: "expected an array of events" }, status: :bad_request unless events.is_a?(Array)

        # A batch with no events makes an ImportEventsJob that can never do
        # anything, so there's nothing worth saving.
        return render json: { message: "nothing to do" } if events.empty?

        batch = USPS::IVMTR::RawJSONBatch.create!(
          payload: events,
          message_group_id: data["msgGrpId"],
          processed: false
        )
        USPS::IVMTR::ImportEventsJob.perform_later(batch)
        render json: { message: "hey, thanks!" }
      end
    end
  end
end
