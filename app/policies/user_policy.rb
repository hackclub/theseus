class UserPolicy < ApplicationPolicy
  def show?
    user&.admin? || record == user
  end
end
