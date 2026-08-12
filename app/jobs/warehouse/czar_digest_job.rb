# frozen_string_literal: true

class Warehouse::CzarDigestJob < ApplicationJob
  queue_as :default

  def perform
    stale_sku_requests = ::Warehouse::SKURequest
      .where(aasm_state: "submitted")
      .where("submitted_at < ?", 2.days.ago)

    stale_pos = ::Warehouse::PurchaseOrder
      .where(status: "submitted")
      .where("submitted_at < ?", 2.days.ago)

    blocked_pos = ::Warehouse::PurchaseOrder
      .where(status: "approved")
      .includes(line_items: :sku_request)
      .select(&:blocked_on_skus?)

    urgent_pos = ::Warehouse::PurchaseOrder
      .where.not(status: %w[open completed deleted])
      .where.not(required_by_date: nil)
      .where("required_by_date <= ?", 5.days.from_now)
      .includes(:user)

    # Digest for czars
    if stale_sku_requests.any? || stale_pos.any? || blocked_pos.any? || urgent_pos.any?
      Warehouse::CzarMailer.digest(
        stale_sku_requests: stale_sku_requests,
        stale_pos: stale_pos,
        blocked_pos: blocked_pos,
        urgent_pos: urgent_pos
      ).deliver_later
    end

    # Nudge drafters about their own urgent POs still in draft
    urgent_draft_pos = urgent_pos.select(&:draft?)
    urgent_draft_pos.group_by(&:user).each do |user, pos|
      next unless user&.email.present?
      Warehouse::CzarMailer.drafter_urgent_reminder(user: user, purchase_orders: pos).deliver_later
    end
  end
end
