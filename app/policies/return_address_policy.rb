class ReturnAddressPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    user_is_admin || record_belongs_to_user
  end

  def edit?
    update?
  end

  def destroy?
    user_is_admin || record_belongs_to_user
  end

  def set_as_home?
    record_belongs_to_user || record.shared?
  end

  private

  def record_belongs_to_user
    user && record.user == user
  end
end
