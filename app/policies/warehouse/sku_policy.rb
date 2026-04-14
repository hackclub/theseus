class Warehouse::SKUPolicy < ApplicationPolicy
  def index? = user_can_warehouse

  alias_method :show?, :index?

  def new? = user_is_admin

  alias_method :create?, :new?
  alias_method :update?, :new?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user_can_warehouse

      scope.none
    end

    private

    def user_can_warehouse
      user&.can_warehouse? || user&.admin?
    end
  end
end
