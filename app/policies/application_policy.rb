# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_is_admin
  end

  def show?
    user_is_admin
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  def user_is_admin
    user&.admin?
  end

  def user_can_warehouse
    user&.can_warehouse? || user_is_admin
  end

  def record_belongs_to_user
    user && record&.user == user
  end
end
