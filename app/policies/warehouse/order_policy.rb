class Warehouse::OrderPolicy < ApplicationPolicy
  def new?
    user_can_warehouse
  end

  def create?
    user_can_warehouse
  end

  def edit?
    return false unless user_can_warehouse
    record_belongs_to_user || user_is_admin
  end

  def show?
    user_can_warehouse
  end

  def index?
    user_can_warehouse
  end

  def cancel?
    return false unless user_can_warehouse
    record_belongs_to_user || user_is_admin
  end

  def send_to_warehouse?
    return false unless user_can_warehouse
    record_belongs_to_user || user_is_admin
  end
end
