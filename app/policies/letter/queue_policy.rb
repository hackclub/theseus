class Letter::QueuePolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def create_letter?
    user.present?
  end

  alias_method :create_instant_letter?, :create_letter?

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
