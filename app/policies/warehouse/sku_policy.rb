class Warehouse::SKUPolicy < ApplicationPolicy
  def index?
    user_can_warehouse
  end
  def show?
    user_can_warehouse
  end
  def create?
    user_is_admin
  end
  def new?
    user_is_admin
  end
  def update?
    user_is_admin
  end
  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
end
