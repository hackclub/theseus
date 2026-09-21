# frozen_string_literal: true

class Warehouse::ApprovalsController < ApplicationController
  def index
    authorize :warehouse_approval, :index?
    @pending_sku_requests = Warehouse::SKURequest.where(aasm_state: "submitted").includes(:user).order(created_at: :asc)
    @pending_pos = Warehouse::PurchaseOrder.where(status: "submitted").includes(:user, :line_items).order(created_at: :asc)
    @blocked_pos = Warehouse::PurchaseOrder.blocked_on_skus.includes(:user, line_items: :sku_request).order(created_at: :asc)
    render Views::Warehouse::Approvals::Index.new(
      pending_sku_requests: @pending_sku_requests,
      pending_pos: @pending_pos,
      blocked_pos: @blocked_pos
    )
  end
end
