module API
  module V1
    class WarehouseSKUsController < ApplicationController
      before_action :set_sku, only: [ :show ]

      def show
        authorize @sku
        render template: "api/v1/warehouse/skus/show"
      end

      private

      def set_sku
        @sku = policy_scope(::Warehouse::SKU).find_by!(sku: params[:id])
      end
    end
  end
end
