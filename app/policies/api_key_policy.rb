class APIKeyPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def index?
    true
  end

  def new?
    true
  end

  def show?
    record_belongs_to_user || user_is_admin
  end

  def revoke?
    record_belongs_to_user || user_is_admin
  end

  alias_method :create?, :new?
  alias_method :revoke_confirm?, :revoke?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.is_admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
