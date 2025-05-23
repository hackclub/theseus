module Public
  class PackagesController < ApplicationController
    include Frameable
    before_action :set_package

    def show
      if @package.is_a? Warehouse::Order
        render "public/warehouse/orders/show"
      end
    end

    def customs_receipt
      raise ActiveRecord::RecordNotFound unless @package.is_a?(Warehouse::Order) &&
                                                @package.recipient_email == current_public_user&.email &&
                                                !@package.address.us?
    end

    def generate_customs_receipt
      raise ActiveRecord::RecordNotFound unless @package.is_a?(Warehouse::Order) &&
                                                @package.recipient_email == current_public_user&.email &&
                                                !@package.address.us?

      # Queue the job to generate and send the customs receipt
      CustomsReceipt::WarehouseOrderReceiptJob.perform_later(@package.id)

      flash[:success] = "check your email in a little bit!"
      redirect_to public_package_path(@package)
    end

    private

    def set_package
      @package = Warehouse::Order.find_by!(hc_id: params[:id])
    end
  end
end
