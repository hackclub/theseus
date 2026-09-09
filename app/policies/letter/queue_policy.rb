class Letter::QueuePolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def index? = true

  def show? = record_belongs_to_user || user_is_admin

  def new? = user.present?

  def create? = user.present?

  def edit? = record_belongs_to_user || user_is_admin

  alias_method :update?, :edit?

  def destroy? = user_is_admin

  def create_letter?
    user.present?
  end

  def create_instant_letter?
    return false unless user.present?
    return true unless record.indicia?
    user.can_use_indicia?
  end

  def batch?
    record_belongs_to_user || user_is_admin
  end

  def mark_printed_instants_mailed?
    user_is_admin
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user.present?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end
