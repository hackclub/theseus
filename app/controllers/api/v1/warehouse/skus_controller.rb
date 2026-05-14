module API
  module V1
    module Warehouse
      class SKUsController < ApplicationController
        before_action :set_sku, only: [ :show ]

        def show
          authorize @sku
        end

        private

        def set_sku
          @sku = policy_scope(::Warehouse::SKU).find_by!(sku: params[:id])
        end
      end
    end
  end
end
