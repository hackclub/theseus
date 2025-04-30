module Public
  class PackagesController < ApplicationController
    before_action :set_package

    def show
    end

    private
    def set_package
      @package = Warehouse::Order.find_by_public_id!(params[:id])
    end
  end
end