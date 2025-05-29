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

  def update?
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

  def destroy?
    return false unless record.draft?
    return false unless user_can_warehouse
    record_belongs_to_user || user_is_admin
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user_can_warehouse
        scope.where(user: user)
      else
        scope.none
      end
    end

    private

    def user_can_warehouse
      user&.can_warehouse? || user&.admin?
    end
  end
end
