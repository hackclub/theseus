class UserPolicy < ApplicationPolicy
  def show?
    user&.admin? || record == user
  end

  def create?
    user_is_admin
  end
end
