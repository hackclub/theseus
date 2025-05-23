class CustomsReceipt::MSRReceiptJob < ApplicationJob
  queue_as :default

  def perform(msr_id)
    msr = LSV::MarketingShipmentRequest.find(msr_id)

    receiptable = CustomsReceipt::TheseusSpecific.receiptable_from_msr(msr)
    pdf = CustomsReceipt::Generate.run(receiptable)

    # Send the email with PDF attachment
    CustomsReceipt::ReceiptMailer.with(
      email: msr.email,
      order_number: msr.id,
      pdf_data: pdf,
    ).receipt.deliver_now
  end
end
