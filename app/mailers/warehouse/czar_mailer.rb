# frozen_string_literal: true

class Warehouse::CzarMailer < GenericTextMailer
  # Notify czars about a new SKU request submission
  def sku_request_submitted(sku_request)
    @sku_request = sku_request
    @subject = "[theseus] [warehouse] new SKU request: #{sku_request.name}"
    czar_emails.each do |email|
      @recipient = email
      mail(to: email)
    end
  end

  # Notify drafter that their SKU request was returned
  def sku_request_returned(sku_request)
    @sku_request = sku_request
    @subject = "[theseus] [warehouse] SKU request returned: #{sku_request.name}"
    @recipient = sku_request.user.email
    mail(to: sku_request.user.email)
  end

  # Notify drafter that their SKU request was approved
  def sku_request_approved(sku_request)
    @sku_request = sku_request
    @subject = "[theseus] [warehouse] SKU request approved: #{sku_request.name} → #{sku_request.assigned_sku_code}"
    @recipient = sku_request.user.email
    mail(to: sku_request.user.email)
  end

  # Notify czars about a new PO submission
  def po_submitted(purchase_order)
    @purchase_order = purchase_order
    @subject = "[theseus] [warehouse] new PO for review: #{purchase_order.supplier_name}"
    czar_emails.each do |email|
      @recipient = email
      mail(to: email)
    end
  end

  # Notify drafter that their PO was returned
  def po_returned(purchase_order)
    @purchase_order = purchase_order
    @subject = "[theseus] [warehouse] PO returned: #{purchase_order.supplier_name}"
    @recipient = purchase_order.user.email
    mail(to: purchase_order.user.email)
  end

  # Notify drafter that their PO was approved
  def po_approved(purchase_order)
    @purchase_order = purchase_order
    @subject = "[theseus] [warehouse] PO approved: #{purchase_order.supplier_name}"
    @recipient = purchase_order.user.email
    mail(to: purchase_order.user.email)
  end

  # Notify drafter that their PO was auto-returned due to SKU request return
  def po_auto_returned(purchase_order, sku_request)
    @purchase_order = purchase_order
    @sku_request = sku_request
    @subject = "[theseus] [warehouse] PO returned to draft: #{purchase_order.supplier_name}"
    @recipient = purchase_order.user.email
    mail(to: purchase_order.user.email)
  end

  # Daily digest for czars — stale, blocked, urgent items
  def digest(stale_sku_requests:, stale_pos:, blocked_pos:, urgent_pos:)
    @stale_sku_requests = stale_sku_requests
    @stale_pos = stale_pos
    @blocked_pos = blocked_pos
    @urgent_pos = urgent_pos
    @subject = "[theseus] [warehouse] daily approval digest"
    czar_emails.each do |email|
      @recipient = email
      mail(to: email)
    end
  end

  # Nudge drafter about their own POs approaching required_by_date
  def drafter_urgent_reminder(user:, purchase_orders:)
    @user = user
    @purchase_orders = purchase_orders
    @subject = "[theseus] [warehouse] #{purchase_orders.size} PO#{purchase_orders.size == 1 ? '' : 's'} approaching due date"
    @recipient = user.email
    mail(to: user.email)
  end

  private

  def czar_emails
    User.where(is_warehouse_czar: true)
        .where("settings->>'czar_notifications' = ?", "true")
        .pluck(:email)
        .compact
  end
end
