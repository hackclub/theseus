module Public
  class ImpersonationPolicy < ApplicationPolicy
    def new?
      user&.admin? || user&.can_impersonate_public?
    end
    alias_method :create?, :new?
  end
end