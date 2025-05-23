class CustomsReceipt::ReceiptMailer < ApplicationMailer
  def receipt
    @order_number = params[:order_number]
    @pdf_data = params[:pdf_data]
    @recipient = params[:email]

    mail to: @recipient
  end
end
