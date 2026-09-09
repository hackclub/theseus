class Warehouse::SKUPolicy < ApplicationPolicy
  def index?
    user_can_warehouse
  end

  def show?
    user_can_warehouse
  end

  def create?
    false
  end

  def new?
    false
  end

  def update?
    user_is_admin
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.can_warehouse? || user&.admin?
      scope.none
    end
  end
end
