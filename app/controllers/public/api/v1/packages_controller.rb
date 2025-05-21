module Public
  module API
    module V1
      class PackagesController < ApplicationController
        before_action :set_package, only: [:show]

        def index
          @packages = Warehouse::Order.where(recipient_email: current_public_user.email)
        end

        def show
        end

        private

        def set_package
          @package = Warehouse::Order.find_by!(hc_id: params[:id])
        end
      end
    end
  end
end
