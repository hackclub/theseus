class Warehouse::InventoryAlertMailer < GenericTextMailer
  def cost_alert(costless_skus:)
    @costless_skus = costless_skus
    @subject = "[theseus] [warehouse] #{@costless_skus.length} SKU#{@costless_skus.length == 1 ? '' : 's'} blocking dispatch"
    @recipient = "nora@hackclub.com"

    mail to: "dinobox@hackclub.com"
  end

  def category_alert(uncategorized_skus:)
    @uncategorized_skus = uncategorized_skus
    @subject = "[theseus] [warehouse] #{@uncategorized_skus.length} SKU#{@uncategorized_skus.length == 1 ? '' : 's'} need#{@uncategorized_skus.length == 1 ? 's' : ''} categorization"
    @recipient = "nora@hackclub.com"

    mail to: "dinobox@hackclub.com"
  end
end
