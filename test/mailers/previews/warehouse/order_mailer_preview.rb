# Preview all emails at http://localhost:3000/rails/mailers/warehouse/order_mailer
class Warehouse::OrderMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/warehouse/order_mailer/order_created
  def order_created
    Warehouse::OrderMailer.order_created
  end

  # Preview this email at http://localhost:3000/rails/mailers/warehouse/order_mailer/order_shipped
  def order_shipped
    Warehouse::OrderMailer.order_shipped
  end
end
