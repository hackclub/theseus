class Warehouse::TemplatePolicy < ApplicationPolicy
  def index?
    user_can_warehouse
  end
  def create?
    user_can_warehouse
  end
  def update?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end
  def show?
    return true if user_is_admin
    return false unless user_can_warehouse
    record_belongs_to_user || record.public?
  end
end