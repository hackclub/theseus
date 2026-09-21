module API
  module V1
    class WarehouseSKUsController < ApplicationController
      before_action :set_sku, only: [ :show ]

      def index
        authorize ::Warehouse::SKU
        scope = policy_scope(::Warehouse::SKU)
        scope = scope.where(enabled: true).in_inventory unless params[:all] == "true"
        @skus = scope.order(:name)
        render template: "api/v1/warehouse/skus/index"
      end

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
