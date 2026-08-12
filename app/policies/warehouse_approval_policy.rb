# frozen_string_literal: true

class WarehouseApprovalPolicy < ApplicationPolicy
  def index?
    user.warehouse_czar? || user.admin?
  end
end
