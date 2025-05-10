module API
  module V1
    class QZTraysController < ApplicationController
      def cert
        send_data QZTrayService.certificate
      end

      def sign
        send_data QZTrayService.sign(params.require(:request))
      end
    end
  end
end
