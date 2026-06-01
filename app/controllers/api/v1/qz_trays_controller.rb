module API
  module V1
    class QZTraysController < ApplicationController
      before_action :set_cors_headers
      skip_before_action :verify_authenticity_token, only: [:sign]
      skip_before_action :require_not_qz_only!
      skip_before_action :authenticate!, only: [:preflight]

      def cert
        send_data QZTrayService.certificate
      end

      def sign
        send_data QZTrayService.sign(params.require(:request))
      end

      def preflight
        head :ok
      end

      private

      def set_cors_headers
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
      end
    end
  end
end