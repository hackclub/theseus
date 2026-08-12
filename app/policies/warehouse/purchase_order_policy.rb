# frozen_string_literal: true

class Warehouse::PurchaseOrderPolicy < ApplicationPolicy
  def index?
    user_can_warehouse
  end

  def show?
    user_can_warehouse
  end

  def new?
    user_can_warehouse
  end

  def create?
    user_can_warehouse
  end

  def edit?
    (record_belongs_to_user || user_is_admin) && (record.draft? || record.returned?)
  end

  def update?
    edit?
  end

  def destroy?
    (record_belongs_to_user || user_is_admin) && (record.draft? || record.returned?)
  end

  def submit?
    record_belongs_to_user && record.draft?
  end

  def revise?
    (record_belongs_to_user || user_is_admin) && record.returned?
  end

  def approve?
    user.warehouse_czar? && record.submitted?
  end

  def return_for_revision?
    user.warehouse_czar? && record.submitted?
  end

  def send_to_zenventory?
    user.warehouse_czar? && record.approved? && record.all_skus_resolved?
  end

  def sync?
    user_is_admin && record.zenventory_id.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.warehouse_czar? || user&.admin?
        scope.all
      elsif user&.can_warehouse
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end
