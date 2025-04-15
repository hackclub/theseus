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
        data = JSON.parse(request.raw_post)
        batch = USPS::IVMTR::RawJSONBatch.create(
          payload: data["events"],
          message_group_id: data["msgGrpId"],
          processed: false
        )
        USPS::IVMTR::ImportEventsJob.perform_later(batch)
        render json: {message: "hey, thanks!"}
      end

    end

  end
end
