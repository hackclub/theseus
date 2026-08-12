# frozen_string_literal: true

class Warehouse::SKURequestPolicy < ApplicationPolicy
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
    (record_belongs_to_user || user_is_admin) && record.draft?
  end

  def update?
    edit?
  end

  def submit?
    record_belongs_to_user && record.draft?
  end

  def approve?
    user.warehouse_czar? && record.submitted?
  end

  def reject?
    user.warehouse_czar? && record.submitted?
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
