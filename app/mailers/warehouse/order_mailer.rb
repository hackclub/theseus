class Warehouse::OrderMailer < ApplicationMailer
  def order_created
    @order = params[:order]
    @recipient = @order.recipient_email

    mail to: @recipient
  end

  def order_shipped
    @order = params[:order]
    @recipient = @order.recipient_email

    mail to: @recipient
  end
end
