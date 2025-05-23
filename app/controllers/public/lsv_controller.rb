module Public
  class LSVController < ApplicationController
    include Frameable

    def show
      @lsv = LSV::SLUGS[params[:slug].to_sym]&.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @lsv && @lsv.email == current_public_user&.email
    rescue Norairrecord::RecordNotFoundError
      raise ActiveRecord::RecordNotFound
    end

    def customs_receipt
      @msr = LSV::MarketingShipmentRequest.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @msr && @msr.email == current_public_user&.email && @msr.country != "US"
    rescue Norairrecord::RecordNotFoundError
      raise ActiveRecord::RecordNotFound
    end

    def generate_customs_receipt
      @msr = LSV::MarketingShipmentRequest.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @msr && @msr.email == current_public_user&.email && @msr.country != "US"

      CustomsReceipt::MSRReceiptJob.perform_later(@msr.id)

      flash[:success] = "check your email in a little bit!"
      return redirect_to show_lsv_path(slug: "msr", id: @msr.id)
    rescue Norairrecord::RecordNotFoundError
      raise ActiveRecord::RecordNotFound
    end
  end
end
