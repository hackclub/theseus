module Public
  class PackagesController < ApplicationController
    include Frameable
    before_action :set_package

    def show
      if @package.is_a? Warehouse::Order
        render "public/warehouse/orders/show"
      end
    end

    private
    def set_package
      @package = Warehouse::Order.find_by!(hc_id: params[:id])
    end
  end
end