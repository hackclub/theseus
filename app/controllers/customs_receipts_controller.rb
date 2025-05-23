class CustomsReceiptsController < ApplicationController
  def index
    authorize :customs_receipt
  end

  def generate
    authorize :customs_receipt

    return redirect_to customs_receipts_path, alert: "well, ya gotta search for *something*" if params[:search].blank?

    receiptable = get_receiptable(params[:search])

    if receiptable.nil?
      flash[:error] = "couldn't find anything about #{params[:search]}... better luck next time?"
      return redirect_to customs_receipts_path
    end

    send_data CustomsReceipt::Generate.run(receiptable), filename: "customs_receipt.pdf", type: "application/pdf", disposition: "inline"
  end

  private

  def get_receiptable(search)
    order = Warehouse::Order.where("hc_id = :search or tracking_number = :search", search:).first
    return CustomsReceipt::TheseusSpecific.receiptable_from_warehouse_order(order) if order

    sanitized_airtable_search = search.gsub("'", "\\'")

    msr = LSV::MarketingShipmentRequest.first_where(
      "OR({Airtable ID (Automation)} = '#{sanitized_airtable_search}', {Warehouse–Tracking Number} = '#{sanitized_airtable_search}')"
    )

    return CustomsReceipt::TheseusSpecific.receiptable_from_msr(msr) if msr

    nil
  end
end
